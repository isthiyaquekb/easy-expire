import 'package:easyexpire/feature/login/viewmodel/auth_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test_helper.dart';

void main() {
  setupTestEnvironment();

  group('AuthViewModel Field Validation Tests', () {
    late AuthViewModel viewModel;

    setUp(() {
      viewModel = AuthViewModel();
    });

    test('emailValidator requires non-empty email with @ symbol', () {
      expect(
        viewModel.emailValidator(''),
        equals('Please enter a valid email address.'),
      );
      expect(
        viewModel.emailValidator('invalidemail'),
        equals('Please enter a valid email address.'),
      );
      expect(viewModel.emailValidator('test@example.com'), isNull);
    });

    test('passwordValidator requires at least 8 characters', () {
      expect(
        viewModel.passwordValidator(''),
        equals('Please enter a valid password'),
      );
      expect(
        viewModel.passwordValidator('12345'),
        equals('Password requires 8 characters or more'),
      );
      expect(viewModel.passwordValidator('12345678'), isNull);
    });

    test(
      'storeNameValidator and storeAddressValidator require non-empty values',
      () {
        expect(
          viewModel.storeNameValidator(''),
          equals('Please enter a store name.'),
        );
        expect(viewModel.storeNameValidator('My Store'), isNull);

        expect(
          viewModel.storeAddressValidator(''),
          equals('Please enter a store address.'),
        );
        expect(viewModel.storeAddressValidator('123 Market St'), isNull);
      },
    );

    test('togglePasswordVisibility toggles state and notifies listeners', () {
      expect(viewModel.isPasswordVisible, isFalse);
      viewModel.togglePasswordVisibility();
      expect(viewModel.isPasswordVisible, isTrue);
      viewModel.togglePasswordVisibility();
      expect(viewModel.isPasswordVisible, isFalse);
    });
  });
}
