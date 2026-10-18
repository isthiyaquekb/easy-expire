import 'dart:developer';
import 'package:easyexpire/core/services/local_notification_services.dart';
import 'package:easyexpire/core/services/notification_deduplication_service.dart';
import 'package:easyexpire/core/utils/expiry_date_calculator.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';

/// Central coordinator for product notification scheduling, reconciliation,
/// and deduplication across foreground, background, and lifecycle events.
class ProductNotificationCoordinator {
  final NotificationDeduplicationService _deduplicationService;

  ProductNotificationCoordinator({
    NotificationDeduplicationService? deduplicationService,
  }) : _deduplicationService =
           deduplicationService ?? NotificationDeduplicationService();

  /// Derives a stable integer notification ID for a product.
  int getNotificationId(InventoryModel product) {
    final key =
        product.id != null && product.id!.isNotEmpty
            ? product.id!
            : '${product.userId}_${product.productName}_${product.batchNo}';
    return generateStableNotificationId(key);
  }

  /// Cancels all notifications and cleans up state for [product].
  Future<void> cancelProductNotifications(InventoryModel product) async {
    final notifId = getNotificationId(product);
    await LocalNotificationServices.cancelNotification(notifId);
    await _deduplicationService.clearRecord(notifId);
    log(
      "Cancelled and cleared notifications for product: ${product.productName} (ID: $notifId)",
    );
  }

  /// Schedules or reconciles reminders for a single [product] according to business rules.
  Future<void> scheduleProductNotifications(
    InventoryModel product, {
    DateTime? referenceTime,
  }) async {
    final now = referenceTime ?? DateTime.now();
    final notifId = getNotificationId(product);
    final expiryDate = product.expiryDate.toDate();
    final lastNotifiedAt = _deduplicationService.getLastNotified(notifId);

    final decision = evaluateNotificationSchedule(
      productName: product.productName,
      expiryDate: expiryDate,
      referenceTime: now,
      lastNotifiedAt: lastNotifiedAt,
    );

    log(
      "Evaluating schedule for ${product.productName}: tier=${decision.tier}, daysRemaining=${decision.daysRemaining}, shouldNotify=${decision.shouldNotify}",
    );

    if (decision.tier == ExpiryNotificationTier.expired) {
      await cancelProductNotifications(product);
      return;
    }

    if (decision.tier == ExpiryNotificationTier.dailyReminder) {
      // If due today and not yet notified today, display immediate reminder
      if (decision.shouldNotify) {
        await LocalNotificationServices.showSimpleNotification(
          decision.title,
          decision.body,
          product.userId,
          id: notifId,
        );
        await _deduplicationService.recordNotification(notifId, now);
      }

      // Pre-schedule upcoming daily reminders at 09:00 AM local time
      // Bounded up to 7 days ahead to respect iOS 64 pending notification limits.
      final daysToSchedule =
          decision.daysRemaining > 7 ? 7 : decision.daysRemaining;
      for (int i = 1; i <= daysToSchedule; i++) {
        final futureDate = DateTime(
          now.year,
          now.month,
          now.day + i,
          9, // 09:00 AM
          0,
        );

        final futureDaysRemaining = calculateCalendarDaysRemaining(
          expiryDate,
          futureDate,
        );

        if (futureDaysRemaining >= 1) {
          final subId = generateStableNotificationId(
            '${product.productName}_${product.batchNo}_d$i',
          );
          final text =
              futureDaysRemaining == 1
                  ? '${product.productName} will expire tomorrow!'
                  : '${product.productName} will expire in $futureDaysRemaining days!';

          await LocalNotificationServices.scheduleProductNotification(
            id: subId,
            title: 'Product Expiry Alert',
            body: text,
            scheduledDate: futureDate,
            payload: product.userId,
          );
        }
      }
    } else if (decision.tier == ExpiryNotificationTier.zeroDayReminder) {
      if (decision.shouldNotify) {
        await LocalNotificationServices.showSimpleNotification(
          decision.title,
          decision.body,
          product.userId,
          id: notifId,
        );
        await _deduplicationService.recordNotification(notifId, now);
      }

      // Schedule next 2-hour reminders for remaining hours today (until midnight)
      var nextSlot = now.add(const Duration(hours: 2));
      int slotIndex = 1;
      while (nextSlot.day == now.day && slotIndex <= 6) {
        final slotId = generateStableNotificationId(
          '${product.productName}_${product.batchNo}_h$slotIndex',
        );
        await LocalNotificationServices.scheduleProductNotification(
          id: slotId,
          title: 'Product Expires TODAY',
          body: '${product.productName} is expiring today!',
          scheduledDate: nextSlot,
          payload: product.userId,
        );
        nextSlot = nextSlot.add(const Duration(hours: 2));
        slotIndex++;
      }
    }
  }

  /// Reconciles all loaded products against the notification schedule.
  Future<void> reconcileProducts(
    List<InventoryModel> products, {
    DateTime? referenceTime,
  }) async {
    log(
      "Reconciling notification schedules for ${products.length} products...",
    );
    for (final product in products) {
      try {
        await scheduleProductNotifications(
          product,
          referenceTime: referenceTime,
        );
      } catch (e) {
        log("Error reconciling product ${product.productName}: $e");
      }
    }
    log("Product notification reconciliation complete.");
  }

  /// Processes the periodic background check (WorkManager worker execution)
  /// evaluating all user products with deduplication and 2-hour zero-day throttling.
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
    int notificationsSent = 0;

    for (final product in products) {
      try {
        final notifId = getNotificationId(product);
        final expiryDate = product.expiryDate.toDate();
        final lastNotifiedAt = _deduplicationService.getLastNotified(notifId);

        final decision = evaluateNotificationSchedule(
          productName: product.productName,
          expiryDate: expiryDate,
          referenceTime: now,
          lastNotifiedAt: lastNotifiedAt,
        );

        if (decision.tier == ExpiryNotificationTier.expired) {
          // Cancel any stale scheduled notification for expired item
          await LocalNotificationServices.cancelNotification(notifId);
          continue;
        }

        if (decision.shouldNotify) {
          // Deliver notification with unique, stable ID so items don't overwrite each other
          await LocalNotificationServices.showSimpleNotification(
            decision.title,
            decision.body,
            product.userId,
            id: notifId,
          );

          if (logToFirestore != null) {
            await logToFirestore(
              title: decision.title,
              body: decision.body,
              userId: product.userId,
            );
          }

          await _deduplicationService.recordNotification(notifId, now);
          notificationsSent++;
          log(
            "Triggered background notification for ${product.productName} (tier: ${decision.tier}, daysRemaining: ${decision.daysRemaining})",
          );
        } else {
          log(
            "Skipped background notification for ${product.productName}: ${decision.reason}",
          );
        }
      } catch (e) {
        log(
          "Error processing background product check for ${product.productName}: $e",
        );
      }
    }

    return notificationsSent;
  }
}
