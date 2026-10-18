import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/core/services/notification_deduplication_service.dart';
import 'package:easyexpire/core/services/product_notification_coordinator.dart';
import 'package:easyexpire/core/utils/expiry_date_calculator.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import '../../test_helper.dart';

void main() {
  setupTestEnvironment();

  group('Notification System End-to-End Pipeline & Schedule Tests', () {
    late GetStorage storage;
    late NotificationDeduplicationService deduplicationService;
    late ProductNotificationCoordinator coordinator;

    // Use a fixed reference time for deterministic testing
    final now = DateTime(2026, 10, 18, 10, 0, 0);

    setUp(() async {
      await GetStorage.init('notification_pipeline_test');
      storage = GetStorage('notification_pipeline_test');
      await storage.erase();
      deduplicationService = NotificationDeduplicationService(storage: storage);
      coordinator = ProductNotificationCoordinator(
        deduplicationService: deduplicationService,
      );
    });

    test(
      'PHASE 3 & 6: 10 days remaining triggers daily notification (verifying removal of outdated <= 5-day limit)',
      () {
        final expiryDate = now.add(const Duration(days: 10));
        final product = InventoryModel(
          id: 'prod_10_days',
          productName: 'Canned Salmon',
          userId: 'user_123',
          expiryDate: Timestamp.fromDate(expiryDate),
          batchNo: 'B-100',
          quantity: 20,
          daysLeft: 10,
        );

        final decision = evaluateNotificationSchedule(
          productName: product.productName,
          expiryDate: expiryDate,
          referenceTime: now,
        );

        expect(decision.shouldNotify, isTrue);
        expect(decision.tier, equals(ExpiryNotificationTier.dailyReminder));
        expect(decision.daysRemaining, equals(10));
        expect(decision.title, equals('Product Expiry Alert'));
        expect(decision.body, equals('Canned Salmon will expire in 10 days!'));
      },
    );

    test('PHASE 3: 2 days remaining triggers daily notification', () {
      final expiryDate = now.add(const Duration(days: 2));
      final product = InventoryModel(
        id: 'prod_2_days',
        productName: 'Fresh Milk',
        userId: 'user_123',
        expiryDate: Timestamp.fromDate(expiryDate),
        batchNo: 'B-102',
        quantity: 4,
        daysLeft: 2,
      );

      final decision = evaluateNotificationSchedule(
        productName: product.productName,
        expiryDate: expiryDate,
        referenceTime: now,
      );

      expect(decision.shouldNotify, isTrue);
      expect(decision.tier, equals(ExpiryNotificationTier.dailyReminder));
      expect(decision.daysRemaining, equals(2));
      expect(decision.body, equals('Fresh Milk will expire in 2 days!'));
    });

    test(
      'PHASE 3: Exactly 1 day remaining triggers daily reminder with tomorrow wording',
      () {
        final expiryDate = now.add(const Duration(days: 1));
        final product = InventoryModel(
          id: 'prod_1_day',
          productName: 'Yogurt',
          userId: 'user_123',
          expiryDate: Timestamp.fromDate(expiryDate),
          batchNo: 'B-103',
          quantity: 2,
          daysLeft: 1,
        );

        final decision = evaluateNotificationSchedule(
          productName: product.productName,
          expiryDate: expiryDate,
          referenceTime: now,
        );

        expect(decision.shouldNotify, isTrue);
        expect(decision.tier, equals(ExpiryNotificationTier.dailyReminder));
        expect(decision.daysRemaining, equals(1));
        expect(decision.body, equals('Yogurt will expire tomorrow!'));
      },
    );

    test(
      'PHASE 3: Exactly 0 days remaining triggers zero-day alert ("Product Expires TODAY")',
      () {
        final expiryDate = now.add(
          const Duration(hours: 3),
        ); // Same calendar day
        final product = InventoryModel(
          id: 'prod_today',
          productName: 'Sandwich',
          userId: 'user_123',
          expiryDate: Timestamp.fromDate(expiryDate),
          batchNo: 'B-104',
          quantity: 1,
          daysLeft: 0,
        );

        final decision = evaluateNotificationSchedule(
          productName: product.productName,
          expiryDate: expiryDate,
          referenceTime: now,
        );

        expect(decision.shouldNotify, isTrue);
        expect(decision.tier, equals(ExpiryNotificationTier.zeroDayReminder));
        expect(decision.daysRemaining, equals(0));
        expect(decision.title, equals('Product Expires TODAY'));
        expect(decision.body, equals('Sandwich is expiring today!'));
      },
    );

    test(
      'PHASE 3: Expired item (-1 day) suppresses notifications and marks for cancellation',
      () {
        final expiryDate = now.subtract(const Duration(days: 1));
        final product = InventoryModel(
          id: 'prod_expired',
          productName: 'Expired Bread',
          userId: 'user_123',
          expiryDate: Timestamp.fromDate(expiryDate),
          batchNo: 'B-099',
          quantity: 1,
          daysLeft: -1,
        );

        final decision = evaluateNotificationSchedule(
          productName: product.productName,
          expiryDate: expiryDate,
          referenceTime: now,
        );

        expect(decision.shouldNotify, isFalse);
        expect(decision.tier, equals(ExpiryNotificationTier.expired));
        expect(decision.daysRemaining, equals(-1));
      },
    );

    test(
      'PHASE 2 & 3: Daily reminder deduplication prevents duplicate on same calendar day',
      () {
        final expiryDate = now.add(const Duration(days: 4));
        // Prior notification delivered 3 hours ago on the SAME calendar day
        final lastNotified = now.subtract(const Duration(hours: 3));

        final decision = evaluateNotificationSchedule(
          productName: 'Cheese',
          expiryDate: expiryDate,
          referenceTime: now,
          lastNotifiedAt: lastNotified,
        );

        expect(decision.shouldNotify, isFalse);
        expect(decision.reason, contains('Already notified today'));
      },
    );

    test(
      'PHASE 2 & 3: Daily reminder allowed if prior notification was yesterday',
      () {
        final expiryDate = now.add(const Duration(days: 4));
        // Prior notification delivered yesterday
        final lastNotified = now.subtract(const Duration(days: 1));

        final decision = evaluateNotificationSchedule(
          productName: 'Cheese',
          expiryDate: expiryDate,
          referenceTime: now,
          lastNotifiedAt: lastNotified,
        );

        expect(decision.shouldNotify, isTrue);
      },
    );

    test(
      'PHASE 2 & 3: Zero-day alert throttled if less than 120 minutes elapsed',
      () {
        final expiryDate = now; // Same calendar day
        // Prior notification delivered 45 minutes ago
        final lastNotified = now.subtract(const Duration(minutes: 45));

        final decision = evaluateNotificationSchedule(
          productName: 'Salad',
          expiryDate: expiryDate,
          referenceTime: now,
          lastNotifiedAt: lastNotified,
        );

        expect(decision.shouldNotify, isFalse);
        expect(decision.reason, contains('Throttled'));
      },
    );

    test('PHASE 2 & 3: Zero-day alert allowed after 120 minutes elapsed', () {
      final expiryDate = now;
      // Prior notification delivered 125 minutes ago
      final lastNotified = now.subtract(const Duration(minutes: 125));

      final decision = evaluateNotificationSchedule(
        productName: 'Salad',
        expiryDate: expiryDate,
        referenceTime: now,
        lastNotifiedAt: lastNotified,
      );

      expect(decision.shouldNotify, isTrue);
    });

    test(
      'PHASE 2: Stable notification IDs are deterministic and distinct for separate products',
      () {
        final productA = InventoryModel(
          id: 'doc_alpha',
          productName: 'Product A',
          userId: 'user_1',
          expiryDate: Timestamp.fromDate(now),
          batchNo: 'B-1',
          quantity: 1,
          daysLeft: 0,
        );

        final productB = InventoryModel(
          id: 'doc_beta',
          productName: 'Product B',
          userId: 'user_1',
          expiryDate: Timestamp.fromDate(now),
          batchNo: 'B-2',
          quantity: 1,
          daysLeft: 0,
        );

        final idA1 = coordinator.getNotificationId(productA);
        final idA2 = coordinator.getNotificationId(productA);
        final idB = coordinator.getNotificationId(productB);

        // Deterministic
        expect(idA1, equals(idA2));
        // Distinct products receive different IDs (prevents replacing each other)
        expect(idA1, isNot(equals(idB)));
        // Valid 31-bit range
        expect(idA1, greaterThanOrEqualTo(0));
        expect(idB, greaterThanOrEqualTo(0));
      },
    );

    test(
      'PHASE 2: Deduplication service persists and clears records safely',
      () async {
        const notifId = 44556;
        expect(deduplicationService.getLastNotified(notifId), isNull);

        await deduplicationService.recordNotification(notifId, now);
        expect(deduplicationService.getLastNotified(notifId), equals(now));

        await deduplicationService.clearRecord(notifId);
        expect(deduplicationService.getLastNotified(notifId), isNull);
      },
    );

    test(
      'PHASE 4 & 5: Periodic background check evaluates products and records deliveries',
      () async {
        final products = [
          InventoryModel(
            id: 'prod_bg_1',
            productName: 'Apples',
            userId: 'user_bg',
            expiryDate: Timestamp.fromDate(now.add(const Duration(days: 3))),
            batchNo: 'A-1',
            quantity: 10,
            daysLeft: 3,
          ),
          InventoryModel(
            id: 'prod_bg_2',
            productName: 'Juice',
            userId: 'user_bg',
            expiryDate: Timestamp.fromDate(
              now.subtract(const Duration(days: 2)),
            ), // expired
            batchNo: 'J-1',
            quantity: 2,
            daysLeft: -2,
          ),
        ];

        final List<Map<String, String>> loggedFirestore = [];

        final sentCount = await coordinator.processPeriodicBackgroundCheck(
          products,
          referenceTime: now,
          logToFirestore: ({
            required title,
            required body,
            required userId,
          }) async {
            loggedFirestore.add({
              'title': title,
              'body': body,
              'userId': userId,
            });
          },
        );

        // Apples should notify, Juice is expired so should be skipped
        expect(sentCount, equals(1));
        expect(loggedFirestore.length, equals(1));
        expect(loggedFirestore.first['title'], equals('Product Expiry Alert'));
        expect(
          loggedFirestore.first['body'],
          equals('Apples will expire in 3 days!'),
        );

        // Check deduplication was stored
        final notifId = coordinator.getNotificationId(products.first);
        expect(deduplicationService.getLastNotified(notifId), equals(now));

        // Running second time on same day should be throttled
        final secondSentCount = await coordinator
            .processPeriodicBackgroundCheck(
              products,
              referenceTime: now.add(const Duration(hours: 1)),
            );
        expect(secondSentCount, equals(0));
      },
    );
  });
}
