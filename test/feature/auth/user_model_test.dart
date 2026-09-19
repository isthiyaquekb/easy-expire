import 'package:easyexpire/feature/login/model/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel Tests', () {
    test('toMap and fromMap serialize and deserialize correctly', () {
      final user = UserModel(
        id: 'usr_123',
        storeName: 'Quick Pharmacy',
        storeAddress: '123 Main St',
        email: 'store@example.com',
        phoneCode: '+1',
        phone: '5551234567',
      );

      final map = user.toMap();
      expect(map['id'], equals('usr_123'));
      expect(map['store_name'], equals('Quick Pharmacy'));
      expect(map['store_address'], equals('123 Main St'));
      expect(map['email'], equals('store@example.com'));
      expect(map['phone_code'], equals('+1'));
      expect(map['phone'], equals('5551234567'));

      final reconstructed = UserModel.fromMap(map);
      expect(reconstructed.id, equals(user.id));
      expect(reconstructed.storeName, equals(user.storeName));
      expect(reconstructed.storeAddress, equals(user.storeAddress));
      expect(reconstructed.email, equals(user.email));
      expect(reconstructed.phone, equals(user.phone));
    });

    test('UserModel.empty creates blank user object', () {
      final emptyUser = UserModel.empty();
      expect(emptyUser.id, isEmpty);
      expect(emptyUser.storeName, isEmpty);
      expect(emptyUser.email, isEmpty);
    });
  });
}
