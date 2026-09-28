import 'package:easyexpire/core/constant/app_keys.dart';
import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/feature/splash/view_model/splash_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import '../../test_helper.dart';

void main() {
  setupTestEnvironment();

  late SplashProvider splashProvider;
  late GetStorage storageBox;

  setUp(() async {
    await GetStorage.init();
    storageBox = GetStorage();
    await storageBox.erase();
    splashProvider = SplashProvider();
  });

  tearDown(() {
    splashProvider.dispose();
  });

  group('SplashProvider Tests', () {
    test('initial state hasNavigated is false', () {
      expect(splashProvider.hasNavigated, isFalse);
    });

    testWidgets(
      'navigateToHome navigates to onBoard when onboarding not started',
      (tester) async {
        String? navigatedRoute;

        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: (settings) {
              navigatedRoute = settings.name;
              return MaterialPageRoute(
                builder: (context) => const Scaffold(body: Text('Target')),
              );
            },
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => splashProvider.navigateToHome(context),
                  child: const Text('Navigate'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Navigate'));
        await tester.pumpAndSettle();

        expect(splashProvider.hasNavigated, isTrue);
        expect(navigatedRoute, equals(AppRoutes.onBoard));
      },
    );

    testWidgets(
      'navigateToHome navigates to login when onboarding started but not logged in',
      (tester) async {
        storageBox.write(AppKeys.keyIsOnboardingStarted, true);
        storageBox.write(AppKeys.keyIsLoggedIn, false);
        String? navigatedRoute;

        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: (settings) {
              navigatedRoute = settings.name;
              return MaterialPageRoute(
                builder: (context) => const Scaffold(body: Text('Target')),
              );
            },
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => splashProvider.navigateToHome(context),
                  child: const Text('Navigate'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Navigate'));
        await tester.pumpAndSettle();

        expect(splashProvider.hasNavigated, isTrue);
        expect(navigatedRoute, equals(AppRoutes.login));
      },
    );

    testWidgets(
      'navigateToHome navigates to dashboard when onboarding started and logged in',
      (tester) async {
        storageBox.write(AppKeys.keyIsOnboardingStarted, true);
        storageBox.write(AppKeys.keyIsLoggedIn, true);
        String? navigatedRoute;

        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: (settings) {
              navigatedRoute = settings.name;
              return MaterialPageRoute(
                builder: (context) => const Scaffold(body: Text('Target')),
              );
            },
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => splashProvider.navigateToHome(context),
                  child: const Text('Navigate'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Navigate'));
        await tester.pumpAndSettle();

        expect(splashProvider.hasNavigated, isTrue);
        expect(navigatedRoute, equals(AppRoutes.dashboard));
      },
    );

    testWidgets(
      'startTimer triggers navigation exactly once even if called multiple times',
      (tester) async {
        int navigationCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: (settings) {
              navigationCount++;
              return MaterialPageRoute(
                builder: (context) => const Scaffold(body: Text('Target')),
              );
            },
            home: Builder(
              builder: (context) {
                // Simulate multiple build frame triggers
                splashProvider.startTimer(
                  context,
                  duration: const Duration(milliseconds: 100),
                );
                splashProvider.startTimer(
                  context,
                  duration: const Duration(milliseconds: 100),
                );
                return const Scaffold(body: Text('Splash'));
              },
            ),
          ),
        );

        // Advance time past the timer duration
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(navigationCount, equals(1));
        expect(splashProvider.hasNavigated, isTrue);
      },
    );
  });
}
