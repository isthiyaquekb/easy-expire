import 'dart:developer';
import 'dart:math' show min;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/core/constant/expiry_policy.dart';
import 'package:easyexpire/core/utils/expiry_date_calculator.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:easyexpire/feature/notification/model/notification_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

/// Service responsible for managing in-app notification history stored in Cloud Firestore
/// under Users/{uid}/notifications/{productId}.
///
/// ============================================================================
/// IMPORTANT PLATFORM LIMITATION:
/// Scheduled local notifications on iOS and Android are delivered directly by the
/// underlying operating system's notification daemon without executing Dart isolate
/// code when triggered. As a consequence, history entries cannot be written to Firestore
/// at the precise second a pre-scheduled notification fires.
///
/// Instead, notification history entries are written when the application's reconciliation
/// pipeline decides to notify (e.g., during app launch, product add/edit/delete, login,
/// and periodic background execution). Furthermore, upon app launch and resume,
/// `getActiveNotifications()` is queried to sync delivered alerts with Firestore.
/// ============================================================================
class NotificationHistoryService {
  final FirebaseFirestore? _customFirestore;

  NotificationHistoryService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  void _log(String message) {
    if (kDebugMode) {
      log('[NOTIF-HISTORY] $message');
    }
  }

  CollectionReference<Map<String, dynamic>> _userNotificationsRef(
    String userId,
  ) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('notifications');
  }

  /// Formats [timestamp] relative to [referenceTime] (or DateTime.now()):
  /// - < 60 seconds: "just now"
  /// - 1 minute: "1 min ago"; 2..59 minutes: "$mins mins ago" (e.g. "3 mins ago")
  /// - 1 hour: "1 hour ago"; 2..23 hours: "$hours hours ago" (e.g. "2 hours ago")
  /// - Calendar yesterday: "Yesterday"
  /// - Older: formatted date or "$days days ago"
  static String formatRelativeTime(
    DateTime timestamp, {
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'just now';
    }

    final minutes = difference.inMinutes;
    if (minutes < 60) {
      if (minutes == 1) return '1 min ago';
      return '$minutes mins ago';
    }

    final hours = difference.inHours;
    if (hours < 24) {
      if (hours == 1) return '1 hour ago';
      return '$hours hours ago';
    }

    final nowDate = DateTime(now.year, now.month, now.day);
    final timeDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final dayDiff = nowDate.difference(timeDate).inDays;

    if (dayDiff == 1 || (hours >= 24 && hours < 48)) {
      return 'Yesterday';
    }

    if (dayDiff > 1 && dayDiff < 7) {
      return '$dayDiff days ago';
    }

    return DateFormat('dd MMM').format(timestamp);
  }

  /// Reconciles and upserts product notification history records in Firestore.
  ///
  /// - Upserts one doc per product using productId as document ID: `Users/{uid}/notifications/{productId}`.
  /// - Sets `createdAt` ONLY on document creation and preserves it on updates.
  /// - Increments `notifyCount` on each update.
  /// - Resets `isRead` to false on updates.
  /// - Skips writes (throttles) if `updatedAt` is within [throttleMinutes] and `daysRemaining` and `category` are unchanged.
  /// - Deletes notification docs for products removed from inventory or moved out of the warning window (days > warningWindowDays).
  /// - Expired products (< 0): category set to 'expired' and document kept.
  /// - Chunked into batches of $\le 500$ operations (Firestore WriteBatch maximum).
  Future<void> syncNotificationHistory({
    required String userId,
    required List<InventoryModel> products,
    DateTime? referenceTime,
    int throttleMinutes = 30,
  }) async {
    if (userId.isEmpty) {
      _log('syncNotificationHistory skipped: userId is empty');
      return;
    }

    final now = referenceTime ?? DateTime.now();
    final notifsRef = _userNotificationsRef(userId);

    // 1. Fetch all existing notification history documents for this user
    final existingSnapshot = await notifsRef.get();
    final existingDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in existingSnapshot.docs) {
      existingDocs[doc.id] = doc;
    }

    // Map current products by non-empty ID
    final currentProductsMap = <String, InventoryModel>{};
    for (final p in products) {
      if (p.id != null && p.id!.isNotEmpty) {
        currentProductsMap[p.id!] = p;
      }
    }

    final operations = <void Function(WriteBatch batch)>[];
    int createdCount = 0;
    int updatedCount = 0;
    int throttledCount = 0;
    int deletedCount = 0;

    // 2. Identify docs to DELETE:
    // (a) Products that were deleted from the inventory collection.
    // (b) Products that moved out of the warning window (daysRemaining > warningWindowDays).
    for (final entry in existingDocs.entries) {
      final productId = entry.key;
      final currentProd = currentProductsMap[productId];

      if (currentProd == null) {
        // Product no longer exists in inventory -> delete history doc
        operations.add((batch) {
          batch.delete(notifsRef.doc(productId));
        });
        deletedCount++;
        _log('Delete queued for product $productId (removed from inventory)');
      } else {
        final days = calculateCalendarDaysRemaining(
          currentProd.expiryDate.toDate(),
          now,
        );
        if (ExpiryPolicy.isSafe(days)) {
          // Product edited to a safe date beyond warning window -> delete history doc
          operations.add((batch) {
            batch.delete(notifsRef.doc(productId));
          });
          deletedCount++;
          _log(
            'Delete queued for product $productId (moved to safe: $days days)',
          );
        }
      }
    }

    // 3. Process candidate products (urgent, warning, or already-notified expired)
    for (final product in products) {
      final productId = product.id;
      if (productId == null || productId.isEmpty) continue;

      final days = calculateCalendarDaysRemaining(
        product.expiryDate.toDate(),
        now,
      );

      // Safe products are never written to notification history
      if (ExpiryPolicy.isSafe(days)) {
        continue;
      }

      final existingDoc = existingDocs[productId];
      final existingData = existingDoc?.data();

      // Expired items (< 0): only keep/update if a notification doc already exists
      if (ExpiryPolicy.isExpired(days)) {
        if (existingDoc == null) {
          // Never was in warning/urgent window in history; do not create now
          continue;
        }

        const category = 'expired';
        const title = 'Product Expired';
        final body = '${product.productName} has expired!';

        // Check throttle
        if (_shouldThrottle(
          existingData: existingData,
          now: now,
          days: days,
          category: category,
          throttleMinutes: throttleMinutes,
        )) {
          throttledCount++;
          _log(
            'Throttled expired product $productId (${product.productName})',
          );
          continue;
        }

        final notifyCount =
            (existingData?['notifyCount'] is int
                ? existingData!['notifyCount'] as int
                : 1) +
            1;

        operations.add((batch) {
          batch.set(
            notifsRef.doc(productId),
            {
              'notificationId': _getStableNotifId(product),
              'productId': productId,
              'productName': product.productName,
              'batchId': product.batchNo,
              'daysRemaining': days,
              'category': category,
              'title': title,
              'body': body,
              'updatedAt': Timestamp.fromDate(now),
              'notifyCount': notifyCount,
              'isRead': false,
            },
            SetOptions(merge: true),
          );
        });
        updatedCount++;
        _log(
          'Updated notification doc to expired for product $productId (${product.productName})',
        );
        continue;
      }

      // Urgent or Warning window
      final String category = ExpiryPolicy.isUrgent(days) ? 'urgent' : 'warning';
      final String title =
          ExpiryPolicy.isUrgent(days)
              ? 'Product Expires TODAY'
              : 'Product Expiry Alert';
      final String body =
          ExpiryPolicy.isUrgent(days)
              ? '${product.productName} expires TODAY'
              : (days == 1
                  ? '${product.productName} will expire tomorrow!'
                  : '${product.productName} will expire in $days days!');

      // Check throttle
      if (_shouldThrottle(
        existingData: existingData,
        now: now,
        days: days,
        category: category,
        throttleMinutes: throttleMinutes,
      )) {
        throttledCount++;
        _log(
          'Throttled upsert for product $productId (${product.productName}): '
          'recently updated with daysRemaining=$days, category=$category',
        );
        continue;
      }

      if (existingDoc == null || !existingDoc.exists) {
        // Document creation (first notify)
        operations.add((batch) {
          batch.set(notifsRef.doc(productId), {
            'notificationId': _getStableNotifId(product),
            'productId': productId,
            'productName': product.productName,
            'batchId': product.batchNo,
            'daysRemaining': days,
            'category': category,
            'title': title,
            'body': body,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
            'notifyCount': 1,
            'isRead': false,
          });
        });
        createdCount++;
        _log(
          'Created notification doc for product $productId (${product.productName}) at $days days',
        );
      } else {
        // Document update (subsequent notify)
        final notifyCount =
            (existingData?['notifyCount'] is int
                ? existingData!['notifyCount'] as int
                : 1) +
            1;

        operations.add((batch) {
          batch.set(
            notifsRef.doc(productId),
            {
              'notificationId': _getStableNotifId(product),
              'productId': productId,
              'productName': product.productName,
              'batchId': product.batchNo,
              'daysRemaining': days,
              'category': category,
              'title': title,
              'body': body,
              'updatedAt': Timestamp.fromDate(now),
              'notifyCount': notifyCount,
              'isRead': false,
            },
            SetOptions(merge: true),
          );
        });
        updatedCount++;
        _log(
          'Updated notification doc for product $productId (${product.productName}): '
          'daysRemaining=$days, notifyCount=$notifyCount',
        );
      }
    }

    // 4. Commit operations in batches of at most 500 (Firestore limit)
    const maxBatchSize = 500;
    for (int i = 0; i < operations.length; i += maxBatchSize) {
      final chunk = operations.sublist(
        i,
        min(i + maxBatchSize, operations.length),
      );
      final batch = _firestore.batch();
      for (final op in chunk) {
        op(batch);
      }
      await batch.commit();
    }

    _log(
      'Sync summary for user $userId: '
      'created=$createdCount, updated=$updatedCount, throttled=$throttledCount, deleted=$deletedCount',
    );
  }

  bool _shouldThrottle({
    required Map<String, dynamic>? existingData,
    required DateTime now,
    required int days,
    required String category,
    required int throttleMinutes,
  }) {
    if (existingData == null) return false;

    final existingUpdated = existingData['updatedAt'];
    DateTime? existingUpdatedAt;
    if (existingUpdated is Timestamp) {
      existingUpdatedAt = existingUpdated.toDate();
    } else if (existingUpdated is String) {
      existingUpdatedAt = DateTime.tryParse(existingUpdated);
    }

    if (existingUpdatedAt == null) return false;

    final existingDays = existingData['daysRemaining'] as int?;
    final existingCat = existingData['category'] as String?;

    return now.difference(existingUpdatedAt).inMinutes < throttleMinutes &&
        existingDays == days &&
        existingCat == category;
  }

  int _getStableNotifId(InventoryModel product) {
    final key =
        product.id != null && product.id!.isNotEmpty
            ? product.id!
            : '${product.userId}_${product.productName}_${product.batchNo}';
    return generateStableNotificationId(key);
  }

  /// Marks a specific notification document as read (`isRead: true`).
  Future<void> markAsRead({
    required String userId,
    required String productId,
  }) async {
    try {
      await _userNotificationsRef(userId).doc(productId).update({
        'isRead': true,
      });
      _log('Marked notification for product $productId as read');
    } catch (e) {
      _log('Error marking notification for product $productId as read: $e');
    }
  }

  /// Marks all unread notification documents for [userId] as read in a batched write.
  Future<void> markAllAsRead({required String userId}) async {
    try {
      final snapshot =
          await _userNotificationsRef(userId)
              .where('isRead', isEqualTo: false)
              .get();

      if (snapshot.docs.isEmpty) return;

      const maxBatchSize = 500;
      for (int i = 0; i < snapshot.docs.length; i += maxBatchSize) {
        final chunk = snapshot.docs.sublist(
          i,
          min(i + maxBatchSize, snapshot.docs.length),
        );
        final batch = _firestore.batch();
        for (final doc in chunk) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }

      _log('Marked all ${snapshot.docs.length} notifications as read');
    } catch (e) {
      _log('Error marking all notifications as read: $e');
    }
  }

  /// Deletes a specific notification document.
  Future<void> deleteNotification({
    required String userId,
    required String productId,
  }) async {
    try {
      await _userNotificationsRef(userId).doc(productId).delete();
      _log('Deleted notification doc for product $productId');
    } catch (e) {
      _log('Error deleting notification doc for product $productId: $e');
    }
  }

  /// Streams notifications for [userId] ordered by `updatedAt` descending.
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _userNotificationsRef(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          _log(
            'Stream snapshot received: ${snapshot.docs.length} notifications for user $userId',
          );
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Syncs delivered active local notifications with Firestore, refreshing `updatedAt`.
  Future<void> syncDeliveredNotifications({
    required String userId,
    required List<ActiveNotification> activeNotifications,
    DateTime? referenceTime,
  }) async {
    if (userId.isEmpty || activeNotifications.isEmpty) return;

    final now = referenceTime ?? DateTime.now();
    final notifsRef = _userNotificationsRef(userId);

    final activeIds = activeNotifications.map((n) => n.id).toSet();
    final snapshot = await notifsRef.get();

    final batch = _firestore.batch();
    int syncedCount = 0;

    for (final doc in snapshot.docs) {
      final notifId = doc.data()['notificationId'] as int?;
      if (notifId != null && activeIds.contains(notifId)) {
        batch.update(doc.reference, {'updatedAt': Timestamp.fromDate(now)});
        syncedCount++;
      }
    }

    if (syncedCount > 0) {
      await batch.commit();
      _log(
        'Refreshed updatedAt for $syncedCount delivered notifications matching active tray',
      );
    }
  }
}
