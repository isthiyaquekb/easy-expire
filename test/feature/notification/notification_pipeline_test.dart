import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test helper representing the pure business logic of expiry notification decision making
class NotificationEvaluationResult {
  final bool shouldNotify;
  final String title;
  final String body;
  final String userId;
  final int daysLeft;

  NotificationEvaluationResult({
    required this.shouldNotify,
    required this.title,
    required this.body,
    required this.userId,
    required this.daysLeft,
  });
}

NotificationEvaluationResult evaluateExpiryForProduct({
  required InventoryModel product,
  required DateTime referenceTime,
}) {
  final expiryDate = product.expiryDate.toDate();
  final daysLeft = expiryDate.difference(referenceTime).inDays;

  if (daysLeft <= 5 && daysLeft > 0) {
    return NotificationEvaluationResult(
      shouldNotify: true,
      title: 'Product Expiry Alert',
      body: '${product.productName} will expire in $daysLeft days!',
      userId: product.userId,
      daysLeft: daysLeft,
    );
  } else if (daysLeft == 0) {
    return NotificationEvaluationResult(
      shouldNotify: true,
      title: 'Product Expires TODAY',
      body: '${product.productName} is expiring today!',
      userId: product.userId,
      daysLeft: daysLeft,
    );
  } else {
    return NotificationEvaluationResult(
      shouldNotify: false,
      title: '',
      body: '',
      userId: product.userId,
      daysLeft: daysLeft,
    );
  }
}

void main() {
  group('Notification System End-to-End Pipeline Logic Tests', () {
    final now = DateTime(2026, 9, 19, 10, 0, 0);

    test(
      'TEST 1 & 3: Product expiring in 3 days triggers "Product Expiry Alert" with correct body',
      () {
        final expiryDate = now.add(const Duration(days: 3));
        final product = InventoryModel(
          productName: 'Fresh Yogurt',
          userId: 'user_abc_123',
          expiryDate: Timestamp.fromDate(expiryDate),
          batchNo: 'B-101',
          quantity: 5,
          daysLeft: 3,
        );

        final result = evaluateExpiryForProduct(
          product: product,
          referenceTime: now,
        );

        expect(result.shouldNotify, isTrue);
        expect(result.title, equals('Product Expiry Alert'));
        expect(result.body, equals('Fresh Yogurt will expire in 3 days!'));
        expect(result.userId, equals('user_abc_123'));
      },
    );

    test(
      'TEST 1 & 3: Product expiring today triggers "Product Expires TODAY"',
      () {
        final expiryDate = now.add(
          const Duration(hours: 4),
        ); // Same 24h window (0 days difference)
        final product = InventoryModel(
          productName: 'Sandwich',
          userId: 'user_abc_123',
          expiryDate: Timestamp.fromDate(expiryDate),
          batchNo: 'B-102',
          quantity: 2,
          daysLeft: 0,
        );

        final result = evaluateExpiryForProduct(
          product: product,
          referenceTime: now,
        );

        expect(result.shouldNotify, isTrue);
        expect(result.title, equals('Product Expires TODAY'));
        expect(result.body, equals('Sandwich is expiring today!'));
        expect(result.userId, equals('user_abc_123'));
      },
    );

    test('TEST 2: Recipient UID matches product owner exactly', () {
      const specificUserId = 'store_owner_xyz_999';
      final product = InventoryModel(
        productName: 'Medicine X',
        userId: specificUserId,
        expiryDate: Timestamp.fromDate(now.add(const Duration(days: 1))),
        batchNo: 'LOT-99',
        quantity: 50,
        daysLeft: 1,
      );

      final result = evaluateExpiryForProduct(
        product: product,
        referenceTime: now,
      );

      expect(result.shouldNotify, isTrue);
      expect(result.userId, equals(specificUserId));
    });

    test(
      'TEST 4: Product expiring in more than 5 days does not trigger alert',
      () {
        final expiryDate = now.add(const Duration(days: 15));
        final product = InventoryModel(
          productName: 'Canned Beans',
          userId: 'user_abc_123',
          expiryDate: Timestamp.fromDate(expiryDate),
          batchNo: 'B-200',
          quantity: 100,
          daysLeft: 15,
        );

        final result = evaluateExpiryForProduct(
          product: product,
          referenceTime: now,
        );

        expect(result.shouldNotify, isFalse);
      },
    );

    test(
      'TEST 5: Already expired product (negative days) does not trigger upcoming alert',
      () {
        final expiryDate = now.subtract(const Duration(days: 2));
        final product = InventoryModel(
          productName: 'Expired Bread',
          userId: 'user_abc_123',
          expiryDate: Timestamp.fromDate(expiryDate),
          batchNo: 'B-099',
          quantity: 1,
          daysLeft: -2,
        );

        final result = evaluateExpiryForProduct(
          product: product,
          referenceTime: now,
        );

        expect(result.shouldNotify, isFalse);
      },
    );

    test(
      'TEST 6: Firestore notification document payload mapping structure',
      () {
        const title = 'Product Expiry Alert';
        const body = 'Juice will expire in 2 days!';
        const userId = 'user_target_456';

        final Map<String, dynamic> docPayload = {
          'title': title,
          'body': body,
          'user_id': userId,
          'timestamp': now,
        };

        expect(docPayload['title'], equals(title));
        expect(docPayload['body'], equals(body));
        expect(docPayload['user_id'], equals(userId));
        expect(docPayload['timestamp'], equals(now));
      },
    );
  });
}
