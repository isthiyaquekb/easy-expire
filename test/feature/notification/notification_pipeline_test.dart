import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/core/constant/expiry_policy.dart';
import 'package:easyexpire/core/services/local_notification_services.dart';
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

    // Use a fixed reference time for deterministic testing (10:00 AM)
    final now = DateTime(2026, 10, 18, 10, 0, 0);

    setUp(() async {
      MockNotificationState.reset();
      await GetStorage.init('notification_pipeline_test');
      storage = GetStorage('notification_pipeline_test');
      await storage.erase();
      deduplicationService = NotificationDeduplicationService(storage: storage);
      coordinator = ProductNotificationCoordinator(
        deduplicationService: deduplicationService,
      );
    });

    test(
      'ExpiryPolicy thresholds: warningWindowDays (4 days) notifies; warningWindowDays + 1 (5 days) is safe',
      () {
        final expiryWindow = now.add(
          Duration(days: ExpiryPolicy.warningWindowDays),
        );
        final decisionWindow = evaluateNotificationSchedule(
          productName: 'Window Item',
          expiryDate: expiryWindow,
          referenceTime: now,
        );
        expect(decisionWindow.shouldNotify, isTrue);
        expect(
          decisionWindow.tier,
          equals(ExpiryNotificationTier.dailyReminder),
        );
        expect(
          decisionWindow.daysRemaining,
          equals(ExpiryPolicy.warningWindowDays),
        );

        final expirySafe = now.add(
          Duration(days: ExpiryPolicy.warningWindowDays + 1),
        );
        final decisionSafe = evaluateNotificationSchedule(
          productName: 'Safe Item',
          expiryDate: expirySafe,
          referenceTime: now,
        );
        expect(decisionSafe.shouldNotify, isFalse);
        expect(decisionSafe.tier, equals(ExpiryNotificationTier.safe));
        expect(
          decisionSafe.daysRemaining,
          equals(ExpiryPolicy.warningWindowDays + 1),
        );
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
      'PHASE 4 & 5: Periodic background check evaluates products and delivers category digest',
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

        // Apples is in warning window -> delivers 1 warning digest; Juice is expired
        expect(sentCount, equals(1));
        expect(loggedFirestore.length, equals(1));
        expect(loggedFirestore.first['title'], equals('Product Expiry Alert'));
        expect(loggedFirestore.first['body'], contains('Apples'));

        // Check deduplication was stored for warning digest ID
        final warningId = DigestNotificationKeys.warningId(now);
        expect(deduplicationService.getLastNotified(warningId), equals(now));

        // Running second time on same day should be throttled
        final secondSentCount = await coordinator
            .processPeriodicBackgroundCheck(
              products,
              referenceTime: now.add(const Duration(hours: 1)),
            );
        expect(secondSentCount, equals(0));
      },
    );

    // =========================================================================
    // SPECIFIC REQUIRED TEST SCENARIOS
    // =========================================================================

    test('REQUIRED: days == window notifies; days == window + 1 does not', () async {
      final productWindow = InventoryModel(
        id: 'p_window_4',
        productName: 'Yogurt 4d',
        userId: 'u1',
        expiryDate: Timestamp.fromDate(
          now.add(Duration(days: ExpiryPolicy.warningWindowDays)),
        ),
        batchNo: 'B4',
        quantity: 1,
        daysLeft: ExpiryPolicy.warningWindowDays,
      );

      final productSafe = InventoryModel(
        id: 'p_safe_5',
        productName: 'Butter 5d',
        userId: 'u1',
        expiryDate: Timestamp.fromDate(
          now.add(Duration(days: ExpiryPolicy.warningWindowDays + 1)),
        ),
        batchNo: 'B5',
        quantity: 1,
        daysLeft: ExpiryPolicy.warningWindowDays + 1,
      );

      // Reconcile product at window threshold (4 days)
      await coordinator.reconcileProducts([productWindow], referenceTime: now);
      // Since now is 10:00 AM (past 09:00), an immediate warning digest was shown
      expect(MockNotificationState.shownNotifications.length, equals(1));
      expect(
        MockNotificationState.shownNotifications.first['body'],
        contains('Yogurt 4d'),
      );

      // Reset and reconcile product at window + 1 (5 days)
      MockNotificationState.reset();
      await coordinator.reconcileProducts([productSafe], referenceTime: now);
      final pendingSafe =
          await LocalNotificationServices.getPendingNotifications();
      expect(pendingSafe, isEmpty);
      expect(MockNotificationState.shownNotifications, isEmpty);
    });

    test('REQUIRED: 8 and 32 days: nothing scheduled, nothing pending', () async {
      final prod8 = InventoryModel(
        id: 'p_8',
        productName: 'Rice 8d',
        userId: 'u1',
        expiryDate: Timestamp.fromDate(now.add(const Duration(days: 8))),
        batchNo: 'B8',
        quantity: 5,
        daysLeft: 8,
      );
      final prod32 = InventoryModel(
        id: 'p_32',
        productName: 'Flour 32d',
        userId: 'u1',
        expiryDate: Timestamp.fromDate(now.add(const Duration(days: 32))),
        batchNo: 'B32',
        quantity: 10,
        daysLeft: 32,
      );

      await coordinator.reconcileProducts([prod8, prod32], referenceTime: now);

      final pending = await LocalNotificationServices.getPendingNotifications();
      expect(pending, isEmpty);
      expect(MockNotificationState.shownNotifications, isEmpty);
    });

    test(
      'REQUIRED: Edit product from 3 days to 30 days: pending notification is cancelled',
      () async {
        final prod = InventoryModel(
          id: 'prod_edit',
          productName: 'Fresh Cream',
          userId: 'u1',
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 3))),
          batchNo: 'BC3',
          quantity: 2,
          daysLeft: 3,
        );

        // Initially at 3 days: future digests are pre-scheduled (for day 1, 2, 3)
        await coordinator.reconcileProducts([prod], referenceTime: now);
        var pending = await LocalNotificationServices.getPendingNotifications();
        expect(pending, isNotEmpty);

        // Edit product to 30 days (moved safely beyond warning window)
        final editedProd = InventoryModel(
          id: 'prod_edit',
          productName: 'Fresh Cream',
          userId: 'u1',
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 30))),
          batchNo: 'BC3',
          quantity: 2,
          daysLeft: 30,
        );

        await coordinator.reconcileProducts([editedProd], referenceTime: now);

        // Obsolete pending notifications must be cancelled
        pending = await LocalNotificationServices.getPendingNotifications();
        expect(pending, isEmpty);
      },
    );

    test(
      'REQUIRED: 1000 products at 3 days: exactly ONE warning digest, not 1000',
      () async {
        final thousandProducts = List.generate(
          1000,
          (i) => InventoryModel(
            id: 'prod_$i',
            productName: 'Item $i',
            userId: 'user_bulk',
            expiryDate: Timestamp.fromDate(now.add(const Duration(days: 3))),
            batchNo: 'BATCH_$i',
            quantity: 1,
            daysLeft: 3,
          ),
        );

        await coordinator.reconcileProducts(
          thousandProducts,
          referenceTime: now,
        );

        // For today: exactly ONE warning digest delivered, NOT 1000
        expect(MockNotificationState.shownNotifications.length, equals(1));
        final shown = MockNotificationState.shownNotifications.first;
        expect(shown['title'], equals('Product Expiry Alert'));
        expect(
          shown['body'],
          contains(
            '1000 products expire within ${ExpiryPolicy.warningWindowDays} days',
          ),
        );

        // Pre-scheduled across the next 7 days: exactly ONE digest per scheduled day (3 days ahead)
        final pending =
            await LocalNotificationServices.getPendingNotifications();
        expect(pending.length, equals(3));
        expect(pending.length, isNot(equals(1000)));
      },
    );

    test(
      'REQUIRED: Mixed set (0, 3, 4, 8, 32): one urgent digest and one warning digest only',
      () async {
        final prod0 = InventoryModel(
          id: 'p_0',
          productName: 'Sandwich',
          userId: 'u1',
          expiryDate: Timestamp.fromDate(now),
          batchNo: 'B0',
          quantity: 1,
          daysLeft: 0,
        );
        final prod3 = InventoryModel(
          id: 'p_3',
          productName: 'Milk',
          userId: 'u1',
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 3))),
          batchNo: 'B3',
          quantity: 2,
          daysLeft: 3,
        );
        final prod4 = InventoryModel(
          id: 'p_4',
          productName: 'Cheese',
          userId: 'u1',
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 4))),
          batchNo: 'B4',
          quantity: 1,
          daysLeft: 4,
        );
        final prod8 = InventoryModel(
          id: 'p_8',
          productName: 'Rice',
          userId: 'u1',
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 8))),
          batchNo: 'B8',
          quantity: 5,
          daysLeft: 8,
        );
        final prod32 = InventoryModel(
          id: 'p_32',
          productName: 'Oil',
          userId: 'u1',
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 32))),
          batchNo: 'B32',
          quantity: 1,
          daysLeft: 32,
        );

        await coordinator.reconcileProducts(
          [prod0, prod3, prod4, prod8, prod32],
          referenceTime: now,
        );

        // Shown notifications for today:
        // Exactly ONE Urgent digest (for prod0) and exactly ONE Warning digest (for prod3, prod4)
        final urgentShown =
            MockNotificationState.shownNotifications
                .where((n) => (n['title'] as String).contains('TODAY'))
                .toList();
        final warningShown =
            MockNotificationState.shownNotifications
                .where((n) => (n['title'] as String).contains('Alert'))
                .toList();

        expect(urgentShown.length, equals(1));
        expect(urgentShown.first['body'], equals('Sandwich expires TODAY'));

        expect(warningShown.length, equals(1));
        expect(
          warningShown.first['body'],
          contains(
            '2 products expire within ${ExpiryPolicy.warningWindowDays} days',
          ),
        );
        expect(warningShown.first['body'], contains('Milk in 3 days'));
      },
    );

    test('REQUIRED: Reconcile twice: identical pending set (idempotent)', () async {
      final products = [
        InventoryModel(
          id: 'p_0',
          productName: 'Urgent Item',
          userId: 'u1',
          expiryDate: Timestamp.fromDate(now),
          batchNo: 'B0',
          quantity: 1,
          daysLeft: 0,
        ),
        InventoryModel(
          id: 'p_3',
          productName: 'Warning Item',
          userId: 'u1',
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 3))),
          batchNo: 'B3',
          quantity: 1,
          daysLeft: 3,
        ),
      ];

      // First run
      await coordinator.reconcileProducts(products, referenceTime: now);
      final pendingRun1 =
          await LocalNotificationServices.getPendingNotifications();
      final idsRun1 = pendingRun1.map((p) => p.id).toSet();

      // Second run with the exact same data
      await coordinator.reconcileProducts(products, referenceTime: now);
      final pendingRun2 =
          await LocalNotificationServices.getPendingNotifications();
      final idsRun2 = pendingRun2.map((p) => p.id).toSet();

      // Exact identity check: identical count and identical IDs
      expect(pendingRun2.length, equals(pendingRun1.length));
      expect(idsRun2, equals(idsRun1));
    });

    test('REQUIRED: Product expired (<0): nothing pending', () async {
      final prodExpired = InventoryModel(
        id: 'p_exp',
        productName: 'Expired Chicken',
        userId: 'u1',
        expiryDate: Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        batchNo: 'BEX',
        quantity: 1,
        daysLeft: -2,
      );

      await coordinator.reconcileProducts([prodExpired], referenceTime: now);

      final pending = await LocalNotificationServices.getPendingNotifications();
      expect(pending, isEmpty);
      expect(MockNotificationState.shownNotifications, isEmpty);
    });
  });
}
