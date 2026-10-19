import 'dart:developer';
import 'package:easyexpire/core/constant/expiry_policy.dart';
import 'package:easyexpire/core/services/local_notification_services.dart';
import 'package:easyexpire/core/services/notification_deduplication_service.dart';
import 'package:easyexpire/core/services/notification_history_service.dart';
import 'package:easyexpire/core/utils/expiry_date_calculator.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Category identifiers and deterministic notification key helpers.
class DigestNotificationKeys {
  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  static int urgentId(DateTime date) =>
      generateStableNotificationId('digest_urgent_${dateKey(date)}');

  static int urgentSlotId(DateTime date, int slotIndex) =>
      generateStableNotificationId(
        'digest_urgent_${dateKey(date)}_slot_$slotIndex',
      );

  static int warningId(DateTime date) =>
      generateStableNotificationId('digest_warning_${dateKey(date)}');
}

/// Structured content for digest notifications.
class DigestPayload {
  final String title;
  final String body;
  final int count;

  const DigestPayload({
    required this.title,
    required this.body,
    required this.count,
  });
}

/// Central coordinator for product notifications.
///
/// Implements category digests (Urgent and Warning), 7-day pre-scheduling,
/// idempotent reconciliation, platform limit respect, and in-app Firestore history sync.
///
/// ============================================================================
/// IMPORTANT PLATFORM LIMITATION:
/// Scheduled local notifications on iOS and Android are delivered by the operating
/// system's notification daemon directly without executing Dart isolate code.
/// Therefore, in-app notification history entries in Cloud Firestore cannot be written
/// at the precise second a scheduled local notification is delivered.
///
/// To handle this architectural limitation:
/// 1. History entries are written when the reconciliation pipeline DECIDES to notify
///    (e.g., app open, add/edit/delete, login, or WorkManager periodic task).
/// 2. On app open and on resume, `getActiveNotifications()` is queried to sync
///    delivered notifications and refresh `updatedAt` for those entries.
/// 3. On notification tap, `isRead` is marked true and the user is routed to the product.
/// ============================================================================
class ProductNotificationCoordinator {
  final NotificationDeduplicationService _deduplicationService;
  NotificationHistoryService? _historyService;

  ProductNotificationCoordinator({
    NotificationDeduplicationService? deduplicationService,
    NotificationHistoryService? historyService,
  }) : _deduplicationService =
           deduplicationService ?? NotificationDeduplicationService(),
       _historyService = historyService;

  NotificationHistoryService get historyService =>
      _historyService ??= NotificationHistoryService();

  /// Legacy helper deriving a deterministic ID for a single product (used for individual lookups/cancellations).
  int getNotificationId(InventoryModel product) {
    final key =
        product.id != null && product.id!.isNotEmpty
            ? product.id!
            : '${product.userId}_${product.productName}_${product.batchNo}';
    return generateStableNotificationId(key);
  }

  /// Cancels legacy notifications for [product] and cleans deduplication state.
  Future<void> cancelProductNotifications(InventoryModel product) async {
    final notifId = getNotificationId(product);
    await LocalNotificationServices.cancelNotification(notifId);
    await _deduplicationService.clearRecord(notifId);
    log(
      '[NOTIF] Cancelled individual product notification for: ${product.productName} (ID: $notifId)',
    );
  }

  /// Formats the Urgent Digest message:
  /// - 1 product: "{productName} expires TODAY"
  /// - >1 products: "{N} products expire TODAY: {P1}, {P2}, {P3} and {M} more"
  static DigestPayload buildUrgentDigest(List<InventoryModel> urgentProducts) {
    if (urgentProducts.isEmpty) {
      return const DigestPayload(title: '', body: '', count: 0);
    }
    const title = 'Product Expires TODAY';
    if (urgentProducts.length == 1) {
      final p = urgentProducts.first;
      return DigestPayload(
        title: title,
        body: '${p.productName} expires TODAY',
        count: 1,
      );
    }
    final top3 =
        urgentProducts.take(3).map((p) => p.productName).toList().join(', ');
    final remaining = urgentProducts.length - 3;
    final extra = remaining > 0 ? ' and $remaining more' : '';
    final body = '${urgentProducts.length} products expire TODAY: $top3$extra';
    return DigestPayload(
      title: title,
      body: body,
      count: urgentProducts.length,
    );
  }

  /// Formats the Warning Digest message:
  /// - 1 product: "{productName} expires in {N} days" (or "tomorrow")
  /// - >1 products: "{N} products expire within 4 days ({NearestName} in {M} days)"
  static DigestPayload buildWarningDigest(
    List<InventoryModel> warningProducts,
    DateTime referenceDate,
  ) {
    if (warningProducts.isEmpty) {
      return const DigestPayload(title: '', body: '', count: 0);
    }
    const title = 'Product Expiry Alert';
    if (warningProducts.length == 1) {
      final p = warningProducts.first;
      final days = calculateCalendarDaysRemaining(
        p.expiryDate.toDate(),
        referenceDate,
      );
      final daysText = days == 1 ? 'tomorrow' : 'in $days days';
      return DigestPayload(
        title: title,
        body: '${p.productName} will expire $daysText!',
        count: 1,
      );
    }

    // Find nearest expiring product
    InventoryModel nearest = warningProducts.first;
    int nearestDays = calculateCalendarDaysRemaining(
      nearest.expiryDate.toDate(),
      referenceDate,
    );
    for (int i = 1; i < warningProducts.length; i++) {
      final d = calculateCalendarDaysRemaining(
        warningProducts[i].expiryDate.toDate(),
        referenceDate,
      );
      if (d < nearestDays) {
        nearestDays = d;
        nearest = warningProducts[i];
      }
    }
    final nearestText =
        nearestDays == 1
            ? '${nearest.productName} tomorrow'
            : '${nearest.productName} in $nearestDays days';
    final body =
        '${warningProducts.length} products expire within ${ExpiryPolicy.warningWindowDays} days ($nearestText)';
    return DigestPayload(
      title: title,
      body: body,
      count: warningProducts.length,
    );
  }

  /// Schedules or reconciles reminders for a single [product] by running reconciliation.
  Future<void> scheduleProductNotifications(
    InventoryModel product, {
    DateTime? referenceTime,
  }) async {
    await reconcileProducts([product], referenceTime: referenceTime);
  }

  /// Reconciles all loaded products against the category digest notification schedule.
  ///
  /// Guarantees idempotency: running 10 times leaves the exact same pending set.
  /// Cancels any scheduled notification that is no longer valid or has moved out of window.
  Future<int> reconcileProducts(
    List<InventoryModel> products, {
    DateTime? referenceTime,
    bool syncHistory = true,
    Future<void> Function({
      required String title,
      required String body,
      required String userId,
    })?
    logToFirestore,
  }) async {
    final now = referenceTime ?? DateTime.now();
    log(
      '[NOTIF] Reconcile start: evaluating ${products.length} products at $now',
    );

    int deliveredCount = 0;
    final expectedNotificationIds = <int>{};

    // 1. Group products for TODAY
    final urgentToday = <InventoryModel>[];
    final warningToday = <InventoryModel>[];

    for (final p in products) {
      final days = calculateCalendarDaysRemaining(p.expiryDate.toDate(), now);
      if (ExpiryPolicy.isExpired(days)) {
        log(
          '[NOTIF] Product "${p.productName}": days=$days -> EXPIRED (no alerts)',
        );
      } else if (ExpiryPolicy.isUrgent(days)) {
        log('[NOTIF] Product "${p.productName}": days=$days -> URGENT');
        urgentToday.add(p);
      } else if (ExpiryPolicy.isWarning(days)) {
        log('[NOTIF] Product "${p.productName}": days=$days -> WARNING');
        warningToday.add(p);
      } else {
        log(
          '[NOTIF] Product "${p.productName}": days=$days -> SAFE (no alerts)',
        );
      }
    }

    // 2. Handle TODAY's Urgent items
    if (urgentToday.isNotEmpty) {
      final urgentDigest = buildUrgentDigest(urgentToday);
      final urgentId = DigestNotificationKeys.urgentId(now);

      // Check deduplication (120 min throttle)
      final lastNotified = _deduplicationService.getLastNotified(urgentId);
      final canNotifyNow =
          lastNotified == null || now.difference(lastNotified).inMinutes >= 120;

      if (canNotifyNow) {
        await LocalNotificationServices.showSimpleNotification(
          urgentDigest.title,
          urgentDigest.body,
          'dashboard_urgent',
          id: urgentId,
        );
        await _deduplicationService.recordNotification(urgentId, now);
        deliveredCount++;
        if (logToFirestore != null) {
          await logToFirestore(
            title: urgentDigest.title,
            body: urgentDigest.body,
            userId: urgentToday.first.userId,
          );
        }
        log(
          '[NOTIF] Delivered immediate urgent digest ID=$urgentId ("${urgentDigest.body}")',
        );
      } else {
        log(
          '[NOTIF] Throttled immediate urgent digest ID=$urgentId (sent within last 120m)',
        );
      }

      // Pre-schedule 2-hour slots for the remainder of today (before midnight)
      var nextSlot = now.add(const Duration(hours: 2));
      int slotIndex = 1;
      while (nextSlot.day == now.day && slotIndex <= 12) {
        final slotId = DigestNotificationKeys.urgentSlotId(now, slotIndex);
        expectedNotificationIds.add(slotId);
        await LocalNotificationServices.scheduleProductNotification(
          id: slotId,
          title: urgentDigest.title,
          body: urgentDigest.body,
          scheduledDate: nextSlot,
          payload: 'dashboard_urgent',
          referenceTime: now,
        );
        log(
          '[NOTIF] Scheduled urgent slot $slotIndex at $nextSlot (ID=$slotId)',
        );
        nextSlot = nextSlot.add(const Duration(hours: 2));
        slotIndex++;
      }
    }

    // 3. Handle TODAY's Warning items
    if (warningToday.isNotEmpty) {
      final warningDigest = buildWarningDigest(warningToday, now);
      final warningId = DigestNotificationKeys.warningId(now);

      final today9am = DateTime(now.year, now.month, now.day, 9, 0);
      if (now.isBefore(today9am)) {
        // Before 09:00 AM today: schedule for 09:00 today
        expectedNotificationIds.add(warningId);
        await LocalNotificationServices.scheduleProductNotification(
          id: warningId,
          title: warningDigest.title,
          body: warningDigest.body,
          scheduledDate: today9am,
          payload: 'warning_attention',
          referenceTime: now,
        );
        log(
          '[NOTIF] Scheduled warning digest for 09:00 today (ID=$warningId): "${warningDigest.body}"',
        );
      } else {
        // At or after 09:00 AM today: show immediate if not already notified today
        final lastNotified = _deduplicationService.getLastNotified(warningId);
        final notifiedToday =
            lastNotified != null &&
            calculateCalendarDaysRemaining(now, lastNotified) == 0;

        if (!notifiedToday) {
          await LocalNotificationServices.showSimpleNotification(
            warningDigest.title,
            warningDigest.body,
            'warning_attention',
            id: warningId,
          );
          await _deduplicationService.recordNotification(warningId, now);
          deliveredCount++;
          if (logToFirestore != null) {
            await logToFirestore(
              title: warningDigest.title,
              body: warningDigest.body,
              userId: warningToday.first.userId,
            );
          }
          log(
            '[NOTIF] Delivered immediate warning digest for today (ID=$warningId): "${warningDigest.body}"',
          );
        } else {
          log('[NOTIF] Warning digest ID=$warningId already delivered today');
        }
      }
    }

    // 4. Pre-schedule digests for the next 7 days (Days 1 to 7 at 09:00)
    // Only products currently within the candidate window (not safe or expired today) are pre-scheduled.
    final candidateProducts =
        products.where((p) {
          final daysToday = calculateCalendarDaysRemaining(
            p.expiryDate.toDate(),
            now,
          );
          return !ExpiryPolicy.isSafe(daysToday) &&
              !ExpiryPolicy.isExpired(daysToday);
        }).toList();

    for (int dayOffset = 1; dayOffset <= 7; dayOffset++) {
      final fireDate = DateTime(
        now.year,
        now.month,
        now.day + dayOffset,
        9, // 09:00 AM local
        0,
      );

      final urgentAtFire = <InventoryModel>[];
      final warningAtFire = <InventoryModel>[];

      for (final p in candidateProducts) {
        final daysAtFire = calculateCalendarDaysRemaining(
          p.expiryDate.toDate(),
          fireDate,
        );
        if (ExpiryPolicy.isUrgent(daysAtFire)) {
          urgentAtFire.add(p);
        } else if (ExpiryPolicy.isWarning(daysAtFire)) {
          warningAtFire.add(p);
        }
      }

      if (urgentAtFire.isNotEmpty) {
        final urgentDigest = buildUrgentDigest(urgentAtFire);
        final urgentId = DigestNotificationKeys.urgentId(fireDate);
        expectedNotificationIds.add(urgentId);
        await LocalNotificationServices.scheduleProductNotification(
          id: urgentId,
          title: urgentDigest.title,
          body: urgentDigest.body,
          scheduledDate: fireDate,
          payload: 'dashboard_urgent',
          referenceTime: now,
        );
        log(
          '[NOTIF] Pre-scheduled urgent digest for $fireDate (ID=$urgentId): "${urgentDigest.body}"',
        );
      }

      if (warningAtFire.isNotEmpty) {
        final warningDigest = buildWarningDigest(warningAtFire, fireDate);
        final warningId = DigestNotificationKeys.warningId(fireDate);
        expectedNotificationIds.add(warningId);
        await LocalNotificationServices.scheduleProductNotification(
          id: warningId,
          title: warningDigest.title,
          body: warningDigest.body,
          scheduledDate: fireDate,
          payload: 'warning_attention',
          referenceTime: now,
        );
        log(
          '[NOTIF] Pre-scheduled warning digest for $fireDate (ID=$warningId): "${warningDigest.body}"',
        );
      }
    }

    // 5. Cancel any pending notifications that are no longer valid or expected
    final pendingRequests =
        await LocalNotificationServices.getPendingNotifications();
    for (final request in pendingRequests) {
      if (!expectedNotificationIds.contains(request.id)) {
        await LocalNotificationServices.cancelNotification(request.id);
        await _deduplicationService.clearRecord(request.id);
        log(
          '[NOTIF] Cancelled obsolete pending notification ID: ${request.id} ("${request.title}")',
        );
      }
    }

    // 6. Sync in-app notification history in Cloud Firestore
    if (syncHistory && products.isNotEmpty) {
      final userId = products.first.userId;
      if (userId.isNotEmpty) {
        try {
          await historyService.syncNotificationHistory(
            userId: userId,
            products: products,
            referenceTime: now,
          );
        } catch (e) {
          log('[NOTIF] History sync skipped or failed: $e');
        }
      }
    }

    log(
      '[NOTIF] Reconcile complete. Active pending IDs count: ${expectedNotificationIds.length}',
    );
    return deliveredCount;
  }

  /// Processes the periodic background check (WorkManager worker execution)
  /// evaluating all user products with category digest deduplication.
  Future<int> processPeriodicBackgroundCheck(
    List<InventoryModel> products, {
    DateTime? referenceTime,
    Future<void> Function({
      required String title,
      required String body,
      required String userId,
    })?
    logToFirestore,
  }) async {
    final now = referenceTime ?? DateTime.now();
    log(
      '[NOTIF] Background periodic check invoked at ${now.toIso8601String()} for ${products.length} products',
    );

    // Reconcile pre-scheduled digests and deliver any immediate digests due
    final sentCount = await reconcileProducts(
      products,
      referenceTime: now,
      logToFirestore: logToFirestore,
    );

    log(
      '[NOTIF] Background periodic check completed. Sent $sentCount digests.',
    );
    return sentCount;
  }

  /// Dumps all pending notification requests to log for diagnosis.
  static Future<List<PendingNotificationRequest>>
  dumpPendingNotifications() async {
    final pending = await LocalNotificationServices.getPendingNotifications();
    log(
      '[NOTIF] === PENDING NOTIFICATIONS DUMP (${pending.length} requests) ===',
    );
    for (final req in pending) {
      log(
        '[NOTIF] Request ID: ${req.id}, Title: "${req.title}", Body: "${req.body}", Payload: "${req.payload}"',
      );
    }
    log(
      '[NOTIF] =============================================================',
    );
    return pending;
  }
}
