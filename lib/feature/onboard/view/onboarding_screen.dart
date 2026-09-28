import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/feature/onboard/view_model/onboarding_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = context.read<OnboardingViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Consumer<OnboardingViewModel>(
            builder:
                (context, value, child) => PageView.builder(
                  controller: value.pageController,
                  onPageChanged: (change) {
                    value.changeOnboardPage(change);
                  },
                  itemCount: value.onBoardingPageList.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.12,
                            ),
                            Container(
                              height: MediaQuery.of(context).size.height * 0.6,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Image.asset(
                                value.onBoardingPageList[index].imageAsset,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              value.onBoardingPageList[index].title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              value.onBoardingPageList[index].description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
            left: MediaQuery.of(context).size.width * 0.4,
            right: MediaQuery.of(context).size.width * 0.4,
            child: SmoothPageIndicator(
              controller: onboardingProvider.pageController,
              count: 3,
              effect: ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 12,
                dotColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                activeDotColor: theme.colorScheme.primary,
                expansionFactor: 3,
              ),
            ),
          ),
          Consumer<OnboardingViewModel>(
            builder:
                (context, provider, child) => Positioned(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 30,
                  right: MediaQuery.of(context).viewInsets.right + 24,
                  child:
                      provider.selectedPageIndex != 2
                          ? InkWell(
                            onTap: () => provider.goToNext(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 18.0,
                                  vertical: 8.0,
                                ),
                                child: Center(
                                  child: Text(
                                    "Next",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          : InkWell(
                            onTap: () => provider.goToNext(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 18.0,
                                  vertical: 8.0,
                                ),
                                child: Center(
                                  child: Text(
                                    "Get Started",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                ),
          ),
          Positioned(
            top: MediaQuery.of(context).viewInsets.top + 40,
            right: MediaQuery.of(context).viewInsets.right + 24,
            child: InkWell(
              onTap: () => onboardingProvider.skipOnboarding(context),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4,
                  ),
                  child: Center(
                    child: Text(
                      "Skip",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
