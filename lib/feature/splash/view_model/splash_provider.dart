import 'dart:async';
import 'package:easyexpire/core/constant/app_keys.dart';
import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class SplashProvider extends ChangeNotifier {
  Timer? _timer;
  bool _hasNavigated = false;

  final storageBox = GetStorage();

  bool get hasNavigated => _hasNavigated;

  void startTimer(
    BuildContext context, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (_hasNavigated || (_timer != null && _timer!.isActive)) {
      return;
    }

    storageBox.writeIfNull(AppKeys.keyIsLoggedIn, false);
    storageBox.writeIfNull(AppKeys.keyIsOnboardingStarted, false);

    _timer?.cancel();
    _timer = Timer(duration, () {
      if (context.mounted) {
        navigateToHome(context);
      }
    });
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _hasNavigated = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void navigateToHome(BuildContext context) {
    if (_hasNavigated || !context.mounted) {
      return;
    }
    _hasNavigated = true;
    _timer?.cancel();
    _timer = null;

    final isOnboardingStarted =
        storageBox.read(AppKeys.keyIsOnboardingStarted) == true;
    final isLoggedIn = storageBox.read(AppKeys.keyIsLoggedIn) == true;

    final String targetRoute =
        isOnboardingStarted
            ? (isLoggedIn ? AppRoutes.dashboard : AppRoutes.login)
            : AppRoutes.onBoard;

    Navigator.of(context).pushReplacementNamed(targetRoute);
  }
}
