import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:easyexpire/core/constant/app_keys.dart';
import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/feature/onboard/model/onboarding_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';

class OnboardingViewModel extends ChangeNotifier {
  final storageBox = GetStorage();

  var selectedPageIndex = 0;
  bool get isLastPage => selectedPageIndex == onBoardingPageList.length - 1;
  var pageController = PageController();

  goToNext(BuildContext context) {
    if (isLastPage) {
      storageBox.write(AppKeys.keyIsOnboardingStarted, true);
      final isLoggedIn = storageBox.read(AppKeys.keyIsLoggedIn) == true;
      Navigator.pushReplacementNamed(
        context,
        isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
      );
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
    notifyListeners();
  }

  void skipOnboarding(BuildContext context) {
    storageBox.write(AppKeys.keyIsOnboardingStarted, true);
    final isLoggedIn = storageBox.read(AppKeys.keyIsLoggedIn) == true;
    Navigator.of(
      context,
    ).pushReplacementNamed(isLoggedIn ? AppRoutes.dashboard : AppRoutes.login);
  }

  void reset() {
    selectedPageIndex = 0;
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
    notifyListeners();
  }

  void changeOnboardPage(int pageNumber) {
    selectedPageIndex = pageNumber;
    notifyListeners();
  }

  List<OnBoardingModel> onBoardingPageList = [
    OnBoardingModel(
      AppAssets.onBoard1,
      "Scan to add",
      'Adding inventory made easy by scanning',
    ),
    OnBoardingModel(
      AppAssets.onBoard2,
      "Access Information",
      'Get information about the product by scanning.',
    ),
    OnBoardingModel(
      AppAssets.onBoard3,
      "Scan to track expiry",
      'Keep an eyes on expiry products.',
    ),
  ];
}
