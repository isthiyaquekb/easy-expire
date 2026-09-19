import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InventoryModel Tests', () {
    test('toMap and fromMap serialize and deserialize correctly', () {
      final now = DateTime(2026, 9, 19, 10, 0, 0);
      final timestamp = Timestamp.fromDate(now);

      final model = InventoryModel(
        productName: 'Organic Milk 1L',
        userId: 'usr_456',
        expiryDate: timestamp,
        batchNo: 'B-9988',
        quantity: 24,
        daysLeft: 3,
      );

      final map = model.toMap();
      expect(map['product_name'], equals('Organic Milk 1L'));
      expect(map['user_id'], equals('usr_456'));
      expect(map['expiry_date'], equals(timestamp));
      expect(map['batch_no'], equals('B-9988'));
      expect(map['quantity'], equals(24));
      expect(map['days_left'], equals(3));

      final reconstructed = InventoryModel.fromMap(map);
      expect(reconstructed.productName, equals('Organic Milk 1L'));
      expect(reconstructed.userId, equals('usr_456'));
      expect(reconstructed.batchNo, equals('B-9988'));
      expect(reconstructed.quantity, equals(24));
      expect(reconstructed.daysLeft, equals(3));
      expect(reconstructed.expiryDate.toDate(), equals(now));
    });

    test('fromMap handles missing or invalid expiryDate gracefully', () {
      final mapWithNullDate = {
        'product_name': 'Apple Juice',
        'user_id': 'usr_789',
        'expiry_date': null,
        'batch_no': 'B-001',
        'quantity': 10,
        'days_left': 0,
      };

      final reconstructed = InventoryModel.fromMap(mapWithNullDate);
      expect(reconstructed.productName, equals('Apple Juice'));
      expect(reconstructed.expiryDate, isA<Timestamp>());
    });
  });
}
