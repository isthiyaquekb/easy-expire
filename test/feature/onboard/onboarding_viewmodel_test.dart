import 'package:easyexpire/core/constant/app_keys.dart';
import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/feature/onboard/view_model/onboarding_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import '../../test_helper.dart';

void main() {
  setupTestEnvironment();

  late OnboardingViewModel viewModel;
  late GetStorage storageBox;

  setUp(() async {
    await GetStorage.init();
    storageBox = GetStorage();
    await storageBox.erase();
    viewModel = OnboardingViewModel();
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('OnboardingViewModel Tests', () {
    test('initial state has selectedPageIndex == 0 and 3 pages', () {
      expect(viewModel.selectedPageIndex, equals(0));
      expect(viewModel.isLastPage, isFalse);
      expect(viewModel.onBoardingPageList.length, equals(3));
    });

    test(
      'changeOnboardPage updates selectedPageIndex and notifies listeners',
      () {
        bool notified = false;
        viewModel.addListener(() => notified = true);

        viewModel.changeOnboardPage(2);
        expect(viewModel.selectedPageIndex, equals(2));
        expect(viewModel.isLastPage, isTrue);
        expect(notified, isTrue);
      },
    );

    testWidgets(
      'skipOnboarding writes flag and navigates to login when not logged in',
      (tester) async {
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
                  onPressed: () => viewModel.skipOnboarding(context),
                  child: const Text('Skip'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        expect(storageBox.read(AppKeys.keyIsOnboardingStarted), isTrue);
        expect(navigatedRoute, equals(AppRoutes.login));
      },
    );

    testWidgets(
      'skipOnboarding writes flag and navigates to dashboard when logged in',
      (tester) async {
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
                  onPressed: () => viewModel.skipOnboarding(context),
                  child: const Text('Skip'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        expect(storageBox.read(AppKeys.keyIsOnboardingStarted), isTrue);
        expect(navigatedRoute, equals(AppRoutes.dashboard));
      },
    );

    testWidgets('goToNext on last page completes onboarding and navigates', (
      tester,
    ) async {
      viewModel.changeOnboardPage(2);
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
                onPressed: () => viewModel.goToNext(context),
                child: const Text('Next'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(storageBox.read(AppKeys.keyIsOnboardingStarted), isTrue);
      expect(navigatedRoute, equals(AppRoutes.login));
    });
  });
}
