import 'package:easyexpire/feature/notification/model/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationModel Tests', () {
    test('instantiates with default isRead false', () {
      final now = DateTime(2026, 9, 19, 12, 0, 0);
      final model = NotificationModel(
        id: 'notif_001',
        title: 'Product Expiry Alert',
        body: 'Organic Milk 1L will expire in 3 days!',
        timestamp: now,
      );

      expect(model.id, equals('notif_001'));
      expect(model.title, equals('Product Expiry Alert'));
      expect(model.body, equals('Organic Milk 1L will expire in 3 days!'));
      expect(model.timestamp, equals(now));
      expect(model.isRead, isFalse);
    });

    test('can toggle isRead state', () {
      final model = NotificationModel(
        id: 'notif_002',
        title: 'Product Expires TODAY',
        body: 'Fresh Bread is expiring today!',
        timestamp: DateTime.now(),
        isRead: false,
      );

      model.isRead = true;
      expect(model.isRead, isTrue);
    });
  });
}
