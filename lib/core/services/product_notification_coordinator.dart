import 'dart:developer';
import 'package:easyexpire/core/constant/app_keys.dart';
import 'package:easyexpire/core/constant/expiry_policy.dart';
import 'package:easyexpire/core/services/local_notification_services.dart';
import 'package:easyexpire/core/services/notification_deduplication_service.dart';
import 'package:easyexpire/core/services/notification_history_service.dart';
import 'package:easyexpire/core/utils/expiry_date_calculator.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';

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

  static int expiredProductId(String productId) =>
      generateStableNotificationId('expired_product_$productId');

  static int urgentProductSlotId(String productId, int slotIndex) =>
      generateStableNotificationId(
        'urgent_product_${productId}_slot_$slotIndex',
      );
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
  final GetStorage _storage;

  ProductNotificationCoordinator({
    NotificationDeduplicationService? deduplicationService,
    NotificationHistoryService? historyService,
    GetStorage? storage,
  }) : _deduplicationService =
           deduplicationService ?? NotificationDeduplicationService(),
       _historyService = historyService,
       _storage = storage ?? deduplicationService?.storage ?? GetStorage();

  NotificationHistoryService get historyService =>
      _historyService ??= NotificationHistoryService();

  /// Returns the current dismissal suppression map (productId -> timestampMs).
  Map<String, dynamic> _getDismissedMap() {
    final raw = _storage.read<Map<String, dynamic>>(
      AppKeys.keyDismissedNotifications,
    );
    return raw != null ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  /// Checks if alerts for [productId] are currently suppressed by a 24-hour dismissal.
  bool isProductSuppressed(String productId, [DateTime? referenceTime]) {
    if (productId.isEmpty) return false;
    final now = referenceTime ?? DateTime.now();
    final dismissedMap = _getDismissedMap();
    final ts = dismissedMap[productId];
    if (ts is int) {
      final dismissedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final elapsed = now.difference(dismissedAt);
      if (elapsed >= Duration.zero &&
          elapsed < ExpiryPolicy.dismissalSuppressionDuration) {
        return true;
      }
    }
    return false;
  }

  /// Records a 24-hour dismissal for [productId] at [timestamp].
  void recordDismissal(String productId, [DateTime? timestamp]) {
    if (productId.isEmpty) return;
    final now = timestamp ?? DateTime.now();
    final dismissedMap = _getDismissedMap();
    dismissedMap[productId] = now.millisecondsSinceEpoch;
    _storage.write(AppKeys.keyDismissedNotifications, dismissedMap);
    log('[NOTIF] Recorded 24h dismissal for product $productId at $now');
  }

  /// Clears 24-hour dismissal suppression for [productId].
  void clearProductSuppression(String productId) {
    if (productId.isEmpty) return;
    final dismissedMap = _getDismissedMap();
    if (dismissedMap.containsKey(productId)) {
      dismissedMap.remove(productId);
      _storage.write(AppKeys.keyDismissedNotifications, dismissedMap);
      log('[NOTIF] Cleared 24h dismissal for product $productId');
    }
  }

  /// Policy 6: Resets notification scheduling, throttling, and dismissal state for [productId] only.
  Future<void> resetProductNotificationState(String productId) async {
    if (productId.isEmpty) return;
    clearProductSuppression(productId);
    final expId = DigestNotificationKeys.expiredProductId(productId);
    await LocalNotificationServices.cancelNotification(expId);
    await _deduplicationService.clearRecord(expId);

    for (int slot = 0; slot < 12; slot++) {
      final slotId = DigestNotificationKeys.urgentProductSlotId(
        productId,
        slot,
      );
      await LocalNotificationServices.cancelNotification(slotId);
      await _deduplicationService.clearRecord(slotId);
    }
    log('[NOTIF] Reset notification state for product $productId');
  }

  /// Policy 3: Returns the configured urgent reminder interval for same-day items (2 or 4 hours).
  int get urgentReminderIntervalHours {
    final stored = _storage.read<int>(AppKeys.keyUrgentReminderIntervalHours);
    if (stored == 2 || stored == 4) return stored!;
    return ExpiryPolicy.defaultUrgentIntervalHours;
  }

  /// Policy 3: Updates the configured urgent reminder interval for same-day items (2 or 4 hours).
  void setUrgentReminderIntervalHours(int hours) {
    if (hours == 2 || hours == 4) {
      _storage.write(AppKeys.keyUrgentReminderIntervalHours, hours);
      log('[NOTIF] Set urgent reminder interval to $hours hours');
    }
  }

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
    if (product.id != null && product.id!.isNotEmpty) {
      await resetProductNotificationState(product.id!);
    }
    log(
      '[NOTIF] Cancelled individual product notification for: ${product.productName} (ID: $notifId)',
    );
  }

  /// Formats the Urgent Digest message:
  /// - 1 product: "{productName} expires TODAY"
  /// - >1 products: "{top3 names} +{M} more"
  static DigestPayload buildUrgentDigest(
    List<InventoryModel> urgentProducts, {
    bool isCatchUp = false,
  }) {
    if (urgentProducts.isEmpty) {
      return const DigestPayload(title: '', body: '', count: 0);
    }
    final title = formatUrgentDigestTitle(
      urgentProducts.length,
      isCatchUp: isCatchUp,
    );
    final names = urgentProducts.map((p) => p.productName).toList();
    final body = formatUrgentDigestBody(names);
    return DigestPayload(
      title: title,
      body: body,
      count: urgentProducts.length,
    );
  }

  /// Formats the Warning Digest message:
  /// - 1 product: "{productName} will expire in {N} days!"
  /// - >1 products: "{N} products expire within {window} days. Nearest: {NearestName} in {M} days"
  static DigestPayload buildWarningDigest(
    List<InventoryModel> warningProducts,
    DateTime referenceDate, {
    bool isCatchUp = false,
  }) {
    if (warningProducts.isEmpty) {
      return const DigestPayload(title: '', body: '', count: 0);
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

    final title = formatWarningDigestTitle(
      warningProducts.length,
      isCatchUp: isCatchUp,
    );
    final body = formatWarningDigestBody(
      count: warningProducts.length,
      nearestName: nearest.productName,
      nearestDays: nearestDays,
    );

    return DigestPayload(
      title: title,
      body: body,
      count: warningProducts.length,
    );
  }

  /// Checks if today's digest was already delivered (via FCM or local catch-up/scheduled).
  bool isDigestDeliveredToday(DateTime date) {
    final key = DigestNotificationKeys.dateKey(date);
    final storedDate = _storage.read<String>(AppKeys.keyLastDeliveredDigestDate);
    if (storedDate == key) return true;
    final urgentId = DigestNotificationKeys.urgentId(date);
    final warningId = DigestNotificationKeys.warningId(date);
    final lastUrgent = _deduplicationService.getLastNotified(urgentId);
    final lastWarning = _deduplicationService.getLastNotified(warningId);
    if (lastUrgent != null && calculateCalendarDaysRemaining(date, lastUrgent) == 0) {
      return true;
    }
    if (lastWarning != null && calculateCalendarDaysRemaining(date, lastWarning) == 0) {
      return true;
    }
    return false;
  }

  /// Marks today's digest as delivered in persistent storage.
  void markDigestDeliveredToday(DateTime date) {
    final key = DigestNotificationKeys.dateKey(date);
    _storage.write(AppKeys.keyLastDeliveredDigestDate, key);
  }

  /// Cancels today's pending local digest when an FCM server push has arrived for today.
  Future<void> cancelTodayLocalDigest(DateTime date) async {
    final urgentId = DigestNotificationKeys.urgentId(date);
    final warningId = DigestNotificationKeys.warningId(date);
    await LocalNotificationServices.cancelNotification(urgentId);
    await LocalNotificationServices.cancelNotification(warningId);
    markDigestDeliveredToday(date);
    log('[NOTIF] Cancelled pending local digest for date $date (FCM push arrived)');
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
  /// Pre-schedules digests for the next 7 days at `storeOpeningTime - notifyLeadMinutes` local time.
  Future<int> reconcileProducts(
    List<InventoryModel> products, {
    DateTime? referenceTime,
    String? storeOpeningTime,
    int? notifyLeadMinutes,
    bool syncHistory = true,
    Future<void> Function({
      required String title,
      required String body,
      required String userId,
    })?
    logToFirestore,
  }) async {
    final now = referenceTime ?? DateTime.now();
    final effectiveOpeningTime = storeOpeningTime ??
        _storage.read<String>(AppKeys.keyStoreOpeningTime) ??
        '10:00';
    final effectiveLeadMinutes = notifyLeadMinutes ??
        _storage.read<int>(AppKeys.keyNotifyLeadMinutes) ??
        90;

    log(
      '[NOTIF] Reconcile start: evaluating ${products.length} products at $now (opening=$effectiveOpeningTime, lead=${effectiveLeadMinutes}m)',
    );

    int deliveredCount = 0;
    final expectedNotificationIds = <int>{};

    // 1. Group products for TODAY
    final expiredProducts = <InventoryModel>[];
    final urgentToday = <InventoryModel>[];
    final warningToday = <InventoryModel>[];

    for (final p in products) {
      final days = calculateCalendarDaysRemaining(p.expiryDate.toDate(), now);
      if (ExpiryPolicy.isExpired(days)) {
        log(
          '[NOTIF] Product "${p.productName}": days=$days -> EXPIRED (hourly reminders)',
        );
        expiredProducts.add(p);
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

    // 2. Schedule Hourly Reminders for Already-Expired Products (Policy 2)
    // Excluded from daily digest; suppressed by 24h dismissal if active
    for (final p in expiredProducts) {
      final pId = p.id ?? p.productName;
      if (isProductSuppressed(p.id ?? '', now)) {
        log(
          '[NOTIF] Expired product "${p.productName}" suppressed by 24h dismissal',
        );
        continue;
      }
      final expId = DigestNotificationKeys.expiredProductId(pId);
      expectedNotificationIds.add(expId);
      await LocalNotificationServices.showHourlyRepeatedNotification(
        id: expId,
        title: 'Product Expired',
        body:
            '${p.productName} has expired! Remove from inventory immediately.',
        payload: 'dashboard_expired',
      );
      log(
        '[NOTIF] Scheduled hourly reminders for expired product "${p.productName}" (ID=$expId)',
      );
    }

    // 3. Filter non-suppressed products expiring today for Daily Digest & Urgent Reminders
    final activeUrgentToday =
        urgentToday
            .where((p) => !isProductSuppressed(p.id ?? '', now))
            .toList();

    // 4. Evaluate TODAY's 08:00 AM digest fire time (Policy 1)
    final todayFireTime = computeDigestFireTime(
      date: now,
      storeOpeningTime: effectiveOpeningTime,
      notifyLeadMinutes: effectiveLeadMinutes,
    );
    final todayDateKey = DigestNotificationKeys.dateKey(now);
    final urgentId = DigestNotificationKeys.urgentId(now);
    final warningId = DigestNotificationKeys.warningId(now);

    final bool isFireTimeInFuture = now.isBefore(todayFireTime);

    if (isFireTimeInFuture) {
      // Fire time is in the future today: schedule both urgent and warning digests for todayFireTime
      if (activeUrgentToday.isNotEmpty) {
        final urgentDigest = buildUrgentDigest(activeUrgentToday);
        expectedNotificationIds.add(urgentId);
        await LocalNotificationServices.scheduleProductNotification(
          id: urgentId,
          title: urgentDigest.title,
          body: urgentDigest.body,
          scheduledDate: todayFireTime,
          payload: 'dashboard_urgent',
          referenceTime: now,
        );
        log(
          '[NOTIF] Scheduled urgent digest for today at $todayFireTime (ID=$urgentId): "${urgentDigest.body}"',
        );
      }
      if (warningToday.isNotEmpty) {
        final warningDigest = buildWarningDigest(warningToday, now);
        expectedNotificationIds.add(warningId);
        await LocalNotificationServices.scheduleProductNotification(
          id: warningId,
          title: warningDigest.title,
          body: warningDigest.body,
          scheduledDate: todayFireTime,
          payload: 'warning_attention',
          referenceTime: now,
        );
        log(
          '[NOTIF] Scheduled warning digest for today at $todayFireTime (ID=$warningId): "${warningDigest.body}"',
        );
      }
    } else {
      // Fire time for today has already passed!
      // DO NOT fire immediately on app open unless it's a catch-up
      // (user opens app after fire time AND digest for today was never delivered)
      final bool alreadyDelivered = isDigestDeliveredToday(now);

      if (!alreadyDelivered) {
        // Catch-up: deliver immediate notification labeled clearly
        if (activeUrgentToday.isNotEmpty) {
          final urgentDigest = buildUrgentDigest(
            activeUrgentToday,
            isCatchUp: true,
          );
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
              userId: activeUrgentToday.first.userId,
            );
          }
          log(
            '[NOTIF] Delivered catch-up urgent digest for today (ID=$urgentId): "${urgentDigest.body}"',
          );
        }

        if (warningToday.isNotEmpty) {
          final warningDigest = buildWarningDigest(
            warningToday,
            now,
            isCatchUp: true,
          );
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
            '[NOTIF] Delivered catch-up warning digest for today (ID=$warningId): "${warningDigest.body}"',
          );
        }

        markDigestDeliveredToday(now);
      } else {
        log(
          '[NOTIF] Digest for today ($todayDateKey) already delivered. Skipping immediate notification on app open.',
        );
      }
    }

    // 5. Configurable Same-Day Urgent Reminders for items expiring today (Policy 3)
    final intervalHours = urgentReminderIntervalHours;
    for (final p in activeUrgentToday) {
      final pId = p.id ?? p.productName;
      final baseFire = DateTime(
        now.year,
        now.month,
        now.day,
        ExpiryPolicy.dailyDigestHour,
        ExpiryPolicy.dailyDigestMinute,
      );
      int slotIndex = 1;
      DateTime slotTime = baseFire.add(
        Duration(hours: intervalHours * slotIndex),
      );
      while (slotTime.day == now.day && slotTime.hour < 22) {
        final slotId = DigestNotificationKeys.urgentProductSlotId(
          pId,
          slotIndex,
        );
        expectedNotificationIds.add(slotId);
        if (slotTime.isAfter(now)) {
          await LocalNotificationServices.scheduleProductNotification(
            id: slotId,
            title: 'Product Expires TODAY',
            body: '${p.productName} is expiring today! Pull from stock.',
            scheduledDate: slotTime,
            payload: 'dashboard_urgent',
            referenceTime: now,
          );
          log(
            '[NOTIF] Scheduled same-day urgent slot $slotIndex ($slotTime) for "${p.productName}" (ID=$slotId)',
          );
        }
        slotIndex++;
        slotTime = baseFire.add(Duration(hours: intervalHours * slotIndex));
      }
    }

    // 6. Pre-schedule digests for the next 7 days at storeOpeningTime - notifyLeadMinutes local time
    final candidateProducts = products.where((p) {
      final daysToday = calculateCalendarDaysRemaining(
        p.expiryDate.toDate(),
        now,
      );
      return !ExpiryPolicy.isSafe(daysToday) &&
          !ExpiryPolicy.isExpired(daysToday);
    }).toList();

    for (int dayOffset = 1; dayOffset <= 7; dayOffset++) {
      final futureDate = now.add(Duration(days: dayOffset));
      final fireDate = computeDigestFireTime(
        date: futureDate,
        storeOpeningTime: effectiveOpeningTime,
        notifyLeadMinutes: effectiveLeadMinutes,
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
        final futureUrgentId = DigestNotificationKeys.urgentId(fireDate);
        expectedNotificationIds.add(futureUrgentId);
        await LocalNotificationServices.scheduleProductNotification(
          id: futureUrgentId,
          title: urgentDigest.title,
          body: urgentDigest.body,
          scheduledDate: fireDate,
          payload: 'dashboard_urgent',
          referenceTime: now,
        );
        log(
          '[NOTIF] Pre-scheduled urgent digest for $fireDate (ID=$futureUrgentId): "${urgentDigest.body}"',
        );
      }

      if (warningAtFire.isNotEmpty) {
        final warningDigest = buildWarningDigest(warningAtFire, fireDate);
        final futureWarningId = DigestNotificationKeys.warningId(fireDate);
        expectedNotificationIds.add(futureWarningId);
        await LocalNotificationServices.scheduleProductNotification(
          id: futureWarningId,
          title: warningDigest.title,
          body: warningDigest.body,
          scheduledDate: fireDate,
          payload: 'warning_attention',
          referenceTime: now,
        );
        log(
          '[NOTIF] Pre-scheduled warning digest for $fireDate (ID=$futureWarningId): "${warningDigest.body}"',
        );
      }
    }

    // 4. Cancel any pending notifications that are no longer valid or expected
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

    // 5. Sync in-app notification history in Cloud Firestore
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

  /// Diagnostic helper: Schedules a test digest notification exactly 1 minute in the future.
  Future<void> scheduleTestDigestInOneMinute(List<InventoryModel> products) async {
    final now = DateTime.now();
    final fireTime = now.add(const Duration(minutes: 1));
    log('[NOTIF] Scheduling debug test digest for 1 minute from now: $fireTime');

    final urgent = products.where((p) {
      final days = calculateCalendarDaysRemaining(p.expiryDate.toDate(), fireTime);
      return ExpiryPolicy.isUrgent(days);
    }).toList();

    final warning = products.where((p) {
      final days = calculateCalendarDaysRemaining(p.expiryDate.toDate(), fireTime);
      return ExpiryPolicy.isWarning(days);
    }).toList();

    if (urgent.isNotEmpty) {
      final digest = buildUrgentDigest(urgent);
      final id = generateStableNotificationId('test_urgent_${now.millisecondsSinceEpoch}');
      await LocalNotificationServices.scheduleProductNotification(
        id: id,
        title: '[TEST] ${digest.title}',
        body: digest.body,
        scheduledDate: fireTime,
        payload: 'dashboard_urgent',
      );
      log('[NOTIF] Scheduled test urgent digest: $id');
    }

    if (warning.isNotEmpty) {
      final digest = buildWarningDigest(warning, fireTime);
      final id = generateStableNotificationId('test_warning_${now.millisecondsSinceEpoch}');
      await LocalNotificationServices.scheduleProductNotification(
        id: id,
        title: '[TEST] ${digest.title}',
        body: digest.body,
        scheduledDate: fireTime,
        payload: 'warning_attention',
      );
      log('[NOTIF] Scheduled test warning digest: $id');
    }

    if (urgent.isEmpty && warning.isEmpty) {
      final id = generateStableNotificationId('test_sample_${now.millisecondsSinceEpoch}');
      await LocalNotificationServices.scheduleProductNotification(
        id: id,
        title: '[TEST] Expiry Digest Preview',
        body: 'All products safe! Store opening digest test successful.',
        scheduledDate: fireTime,
        payload: 'dashboard_urgent',
      );
      log('[NOTIF] Scheduled sample test digest: $id');
    }
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
