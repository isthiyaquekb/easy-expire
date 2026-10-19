import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/core/services/notification_history_service.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Notification History Service (Firestore Upsert-Per-Product) Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late NotificationHistoryService historyService;
    const userId = 'user_test_123';

    // Base reference time
    final now = DateTime(2028, 10, 18, 10, 0, 0);

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      historyService = NotificationHistoryService(firestore: fakeFirestore);
    });

    test(
      'REQUIRED: First notify for a product: creates 1 doc with createdAt == updatedAt and notifyCount == 1',
      () async {
        final product = InventoryModel(
          id: 'prod_hershey',
          productName: 'Hershey Chocolate',
          userId: userId,
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 4))),
          batchNo: 'B-404',
          quantity: 2,
          daysLeft: 4,
        );

        await historyService.syncNotificationHistory(
          userId: userId,
          products: [product],
          referenceTime: now,
        );

        final docSnap =
            await fakeFirestore
                .collection('Users')
                .doc(userId)
                .collection('notifications')
                .doc('prod_hershey')
                .get();

        expect(docSnap.exists, isTrue);
        final data = docSnap.data()!;
        expect(data['productId'], equals('prod_hershey'));
        expect(data['productName'], equals('Hershey Chocolate'));
        expect(data['batchId'], equals('B-404'));
        expect(data['daysRemaining'], equals(4));
        expect(data['category'], equals('warning'));
        expect(data['notifyCount'], equals(1));
        expect(data['isRead'], isFalse);

        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final updatedAt = (data['updatedAt'] as Timestamp).toDate();
        expect(createdAt, equals(updatedAt));
      },
    );

    test(
      'REQUIRED: Second notify for the same product (days 4 to 3): still 1 doc, updatedAt newer, createdAt unchanged, notifyCount == 2, daysRemaining == 3',
      () async {
        final productDay4 = InventoryModel(
          id: 'prod_hershey',
          productName: 'Hershey Chocolate',
          userId: userId,
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 4))),
          batchNo: 'B-404',
          quantity: 2,
          daysLeft: 4,
        );

        // Day 4 notify
        await historyService.syncNotificationHistory(
          userId: userId,
          products: [productDay4],
          referenceTime: now,
        );

        final firstSnap =
            await fakeFirestore
                .collection('Users')
                .doc(userId)
                .collection('notifications')
                .doc('prod_hershey')
                .get();
        final initialCreatedAt = (firstSnap.data()!['createdAt'] as Timestamp)
            .toDate();

        // Advance 1 day (now at 3 days remaining)
        final nextDay = now.add(const Duration(days: 1));
        final productDay3 = InventoryModel(
          id: 'prod_hershey',
          productName: 'Hershey Chocolate',
          userId: userId,
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 4))),
          batchNo: 'B-404',
          quantity: 2,
          daysLeft: 3,
        );

        await historyService.syncNotificationHistory(
          userId: userId,
          products: [productDay3],
          referenceTime: nextDay,
        );

        final allDocs =
            await fakeFirestore
                .collection('Users')
                .doc(userId)
                .collection('notifications')
                .get();
        expect(allDocs.docs.length, equals(1));

        final secondSnap = allDocs.docs.first;
        final secondData = secondSnap.data();
        expect(secondData['daysRemaining'], equals(3));
        expect(secondData['notifyCount'], equals(2));
        expect(secondData['isRead'], isFalse);

        final updatedCreatedAt = (secondData['createdAt'] as Timestamp).toDate();
        final updatedUpdatedAt = (secondData['updatedAt'] as Timestamp).toDate();

        // createdAt unchanged, updatedAt newer
        expect(updatedCreatedAt, equals(initialCreatedAt));
        expect(updatedUpdatedAt.isAfter(initialCreatedAt), isTrue);
      },
    );

    test('REQUIRED: Two different products: 2 docs', () async {
      final p1 = InventoryModel(
        id: 'prod_1',
        productName: 'Milk',
        userId: userId,
        expiryDate: Timestamp.fromDate(now.add(const Duration(days: 2))),
        batchNo: 'B-1',
        quantity: 1,
        daysLeft: 2,
      );
      final p2 = InventoryModel(
        id: 'prod_2',
        productName: 'Bread',
        userId: userId,
        expiryDate: Timestamp.fromDate(now.add(const Duration(days: 1))),
        batchNo: 'B-2',
        quantity: 1,
        daysLeft: 1,
      );

      await historyService.syncNotificationHistory(
        userId: userId,
        products: [p1, p2],
        referenceTime: now,
      );

      final snapshot =
          await fakeFirestore
              .collection('Users')
              .doc(userId)
              .collection('notifications')
              .get();
      expect(snapshot.docs.length, equals(2));
      final ids = snapshot.docs.map((d) => d.id).toSet();
      expect(ids, containsAll(['prod_1', 'prod_2']));
    });

    test('REQUIRED: Safe products (8, 32 days): 0 docs', () async {
      final pSafe1 = InventoryModel(
        id: 'prod_safe_8',
        productName: 'Canned Beans',
        userId: userId,
        expiryDate: Timestamp.fromDate(now.add(const Duration(days: 8))),
        batchNo: 'B-8',
        quantity: 1,
        daysLeft: 8,
      );
      final pSafe2 = InventoryModel(
        id: 'prod_safe_32',
        productName: 'Rice Sack',
        userId: userId,
        expiryDate: Timestamp.fromDate(now.add(const Duration(days: 32))),
        batchNo: 'B-32',
        quantity: 1,
        daysLeft: 32,
      );

      await historyService.syncNotificationHistory(
        userId: userId,
        products: [pSafe1, pSafe2],
        referenceTime: now,
      );

      final snapshot =
          await fakeFirestore
              .collection('Users')
              .doc(userId)
              .collection('notifications')
              .get();
      expect(snapshot.docs.length, equals(0));
    });

    test(
      'REQUIRED: Product edited from 3 days to 30 days: doc deleted',
      () async {
        final prodInWindow = InventoryModel(
          id: 'prod_edited',
          productName: 'Yogurt',
          userId: userId,
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 3))),
          batchNo: 'B-3',
          quantity: 1,
          daysLeft: 3,
        );

        // First sync puts it in window (1 doc created)
        await historyService.syncNotificationHistory(
          userId: userId,
          products: [prodInWindow],
          referenceTime: now,
        );

        var snapshot =
            await fakeFirestore
                .collection('Users')
                .doc(userId)
                .collection('notifications')
                .get();
        expect(snapshot.docs.length, equals(1));

        // User edits expiry to 30 days safe
        final prodSafe = InventoryModel(
          id: 'prod_edited',
          productName: 'Yogurt',
          userId: userId,
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 30))),
          batchNo: 'B-3',
          quantity: 1,
          daysLeft: 30,
        );

        await historyService.syncNotificationHistory(
          userId: userId,
          products: [prodSafe],
          referenceTime: now,
        );

        snapshot =
            await fakeFirestore
                .collection('Users')
                .doc(userId)
                .collection('notifications')
                .get();
        expect(snapshot.docs.length, equals(0));
      },
    );

    test('REQUIRED: Product deleted: doc deleted', () async {
      final p1 = InventoryModel(
        id: 'prod_del',
        productName: 'Juice',
        userId: userId,
        expiryDate: Timestamp.fromDate(now.add(const Duration(days: 2))),
        batchNo: 'B-2',
        quantity: 1,
        daysLeft: 2,
      );

      await historyService.syncNotificationHistory(
        userId: userId,
        products: [p1],
        referenceTime: now,
      );

      var snapshot =
          await fakeFirestore
              .collection('Users')
              .doc(userId)
              .collection('notifications')
              .get();
      expect(snapshot.docs.length, equals(1));

      // Product deleted -> synced with empty list
      await historyService.syncNotificationHistory(
        userId: userId,
        products: [],
        referenceTime: now,
      );

      snapshot =
          await fakeFirestore
              .collection('Users')
              .doc(userId)
              .collection('notifications')
              .get();
      expect(snapshot.docs.length, equals(0));
    });

    test(
      'REQUIRED: Products that become expired (< 0): set category: expired, keep the entry',
      () async {
        final p = InventoryModel(
          id: 'prod_will_expire',
          productName: 'Fresh Sushi',
          userId: userId,
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 1))),
          batchNo: 'B-Sushi',
          quantity: 1,
          daysLeft: 1,
        );

        // Put in warning window
        await historyService.syncNotificationHistory(
          userId: userId,
          products: [p],
          referenceTime: now,
        );

        // Now advance 2 days ( sushi is now -1 day expired)
        final twoDaysLater = now.add(const Duration(days: 2));
        final pExpired = InventoryModel(
          id: 'prod_will_expire',
          productName: 'Fresh Sushi',
          userId: userId,
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 1))),
          batchNo: 'B-Sushi',
          quantity: 1,
          daysLeft: -1,
        );

        await historyService.syncNotificationHistory(
          userId: userId,
          products: [pExpired],
          referenceTime: twoDaysLater,
        );

        final docSnap =
            await fakeFirestore
                .collection('Users')
                .doc(userId)
                .collection('notifications')
                .doc('prod_will_expire')
                .get();

        expect(docSnap.exists, isTrue);
        expect(docSnap.data()!['category'], equals('expired'));
        expect(docSnap.data()!['daysRemaining'], equals(-1));
      },
    );

    test(
      'REQUIRED: Reconcile run 10 times in a row: still one doc per product (idempotent), and throttle prevents redundant writes',
      () async {
        final product = InventoryModel(
          id: 'prod_idempotent',
          productName: 'Granola Bar',
          userId: userId,
          expiryDate: Timestamp.fromDate(now.add(const Duration(days: 3))),
          batchNo: 'B-GRAN',
          quantity: 1,
          daysLeft: 3,
        );

        // Run 10 times within 5 minutes (well within the 30-minute throttle window)
        for (int i = 0; i < 10; i++) {
          await historyService.syncNotificationHistory(
            userId: userId,
            products: [product],
            referenceTime: now.add(Duration(seconds: i * 10)),
          );
        }

        final snapshot =
            await fakeFirestore
                .collection('Users')
                .doc(userId)
                .collection('notifications')
                .get();
        expect(snapshot.docs.length, equals(1));

        final doc = snapshot.docs.first.data();
        // Since calls 2-10 were within the throttle window with identical days & category, notifyCount should still be 1!
        expect(doc['notifyCount'], equals(1));
      },
    );

    test(
      'REQUIRED: 1000 products in the window: written via batches, one doc per product',
      () async {
        final thousandProducts = List.generate(
          1000,
          (i) => InventoryModel(
            id: 'prod_bulk_$i',
            productName: 'Bulk Item $i',
            userId: userId,
            expiryDate: Timestamp.fromDate(now.add(const Duration(days: 3))),
            batchNo: 'BATCH_$i',
            quantity: 1,
            daysLeft: 3,
          ),
        );

        await historyService.syncNotificationHistory(
          userId: userId,
          products: thousandProducts,
          referenceTime: now,
        );

        final snapshot =
            await fakeFirestore
                .collection('Users')
                .doc(userId)
                .collection('notifications')
                .get();

        expect(snapshot.docs.length, equals(1000));
      },
    );

    test(
      'REQUIRED: Relative time formatter: "just now", "3 mins ago", "2 hours ago", "Yesterday"',
      () {
        final ref = DateTime(2028, 10, 19, 14, 0, 0);

        // 30 seconds ago -> "just now"
        final tJustNow = ref.subtract(const Duration(seconds: 30));
        expect(
          NotificationHistoryService.formatRelativeTime(
            tJustNow,
            referenceTime: ref,
          ),
          equals('just now'),
        );

        // 3 minutes ago -> "3 mins ago"
        final t3Mins = ref.subtract(const Duration(minutes: 3));
        expect(
          NotificationHistoryService.formatRelativeTime(
            t3Mins,
            referenceTime: ref,
          ),
          equals('3 mins ago'),
        );

        // 2 hours ago -> "2 hours ago"
        final t2Hours = ref.subtract(const Duration(hours: 2));
        expect(
          NotificationHistoryService.formatRelativeTime(
            t2Hours,
            referenceTime: ref,
          ),
          equals('2 hours ago'),
        );

        // Yesterday (calendar yesterday / 26 hours ago) -> "Yesterday"
        final tYesterday = ref.subtract(const Duration(hours: 26));
        expect(
          NotificationHistoryService.formatRelativeTime(
            tYesterday,
            referenceTime: ref,
          ),
          equals('Yesterday'),
        );
      },
    );

    test('Mark as read and mark all as read works properly', () async {
      final p1 = InventoryModel(
        id: 'p_read_1',
        productName: 'Product 1',
        userId: userId,
        expiryDate: Timestamp.fromDate(now.add(const Duration(days: 2))),
        batchNo: 'B-1',
        quantity: 1,
        daysLeft: 2,
      );
      final p2 = InventoryModel(
        id: 'p_read_2',
        productName: 'Product 2',
        userId: userId,
        expiryDate: Timestamp.fromDate(now.add(const Duration(days: 1))),
        batchNo: 'B-2',
        quantity: 1,
        daysLeft: 1,
      );

      await historyService.syncNotificationHistory(
        userId: userId,
        products: [p1, p2],
        referenceTime: now,
      );

      // Verify initially unread
      var s1 =
          await fakeFirestore
              .collection('Users')
              .doc(userId)
              .collection('notifications')
              .doc('p_read_1')
              .get();
      var s2 =
          await fakeFirestore
              .collection('Users')
              .doc(userId)
              .collection('notifications')
              .doc('p_read_2')
              .get();
      expect(s1.data()!['isRead'], isFalse);
      expect(s2.data()!['isRead'], isFalse);

      // Mark single doc as read
      await historyService.markAsRead(userId: userId, productId: 'p_read_1');
      s1 =
          await fakeFirestore
              .collection('Users')
              .doc(userId)
              .collection('notifications')
              .doc('p_read_1')
              .get();
      expect(s1.data()!['isRead'], isTrue);

      // Mark all as read
      await historyService.markAllAsRead(userId: userId);
      s2 =
          await fakeFirestore
              .collection('Users')
              .doc(userId)
              .collection('notifications')
              .doc('p_read_2')
              .get();
      expect(s2.data()!['isRead'], isTrue);
    });
  });
}
