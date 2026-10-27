import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/feature/login/view/forgot_password_screen.dart';
import 'package:easyexpire/feature/login/viewmodel/auth_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
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

    test('AppRoutes.generatedRoutes resolves forgotPassword without throwing', () {
      final route = AppRoutes.generatedRoutes(
        const RouteSettings(name: AppRoutes.forgotPassword),
      );
      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());
    });
  });

  group('AuthViewModel sendPasswordResetEmail Tests', () {
    late FakeFirebaseAuth fakeAuth;
    late AuthViewModel viewModel;

    setUp(() {
      fakeAuth = FakeFirebaseAuth();
      viewModel = AuthViewModel(auth: fakeAuth);
    });

    test('calls sendPasswordResetEmail with trimmed email and succeeds', () async {
      final result = await viewModel.sendPasswordResetEmail('  test@example.com  ');

      expect(fakeAuth.callCount, equals(1));
      expect(fakeAuth.passedEmail, equals('test@example.com'));
      expect(result.success, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('maps user-not-found to user-friendly error message', () async {
      fakeAuth.exceptionToThrow = FirebaseAuthException(
        code: 'user-not-found',
        message: 'There is no user record corresponding to this identifier.',
      );

      final result = await viewModel.sendPasswordResetEmail('notfound@example.com');

      expect(result.success, isFalse);
      expect(result.errorCode, equals('user-not-found'));
      expect(result.errorMessage, equals('No account found with this email address.'));
    });

    test('maps invalid-email to user-friendly error message', () async {
      fakeAuth.exceptionToThrow = FirebaseAuthException(
        code: 'invalid-email',
        message: 'The email address is badly formatted.',
      );

      final result = await viewModel.sendPasswordResetEmail('bademail');

      expect(result.success, isFalse);
      expect(result.errorCode, equals('invalid-email'));
      expect(result.errorMessage, equals('The email address is not valid.'));
    });

    test('maps too-many-requests to user-friendly error message', () async {
      fakeAuth.exceptionToThrow = FirebaseAuthException(
        code: 'too-many-requests',
        message: 'We have blocked all requests from this device due to unusual activity.',
      );

      final result = await viewModel.sendPasswordResetEmail('test@example.com');

      expect(result.success, isFalse);
      expect(result.errorCode, equals('too-many-requests'));
      expect(result.errorMessage, equals('Too many attempts. Please try again later.'));
    });

    test('maps network-request-failed to user-friendly error message', () async {
      fakeAuth.exceptionToThrow = FirebaseAuthException(
        code: 'network-request-failed',
        message: 'A network error occurred.',
      );

      final result = await viewModel.sendPasswordResetEmail('test@example.com');

      expect(result.success, isFalse);
      expect(result.errorCode, equals('network-request-failed'));
      expect(result.errorMessage, equals('Network error. Please check your internet connection.'));
    });

    test('handles generic unexpected exceptions gracefully', () async {
      fakeAuth.genericExceptionToThrow = Exception('Connection timeout');

      final result = await viewModel.sendPasswordResetEmail('test@example.com');

      expect(result.success, isFalse);
      expect(result.errorMessage, equals('An unexpected error occurred. Please try again.'));
    });
  });

  group('ForgotPasswordScreen Widget Tests', () {
    testWidgets('shows success SnackBar when sendPasswordResetEmail succeeds', (tester) async {
      final fakeAuth = FakeFirebaseAuth();
      final authVm = AuthViewModel(auth: fakeAuth);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authVm,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '  user@example.com  ');
      await tester.pump();

      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeAuth.callCount, equals(1));
      expect(fakeAuth.passedEmail, equals('user@example.com'));
      expect(find.textContaining('Password reset link sent to user@example.com'), findsOneWidget);
    });

    testWidgets('shows error SnackBar when FirebaseAuthException occurs and does not show success', (tester) async {
      final fakeAuth = FakeFirebaseAuth();
      fakeAuth.exceptionToThrow = FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user record found.',
      );
      final authVm = AuthViewModel(auth: fakeAuth);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authVm,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'missing@example.com');
      await tester.pump();

      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeAuth.callCount, equals(1));
      expect(find.text('No account found with this email address.'), findsOneWidget);
      expect(find.textContaining('Password reset link sent'), findsNothing);
    });
  });
}

class FakeFirebaseAuth implements FirebaseAuth {
  String? passedEmail;
  FirebaseAuthException? exceptionToThrow;
  Object? genericExceptionToThrow;
  int callCount = 0;

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    callCount++;
    passedEmail = email;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    if (genericExceptionToThrow != null) {
      throw genericExceptionToThrow!;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
