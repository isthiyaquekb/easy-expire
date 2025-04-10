import 'dart:async';
import 'package:easyexpire/core/constant/app_keys.dart';
import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class SplashProvider extends ChangeNotifier {
  Timer? _timer;

  final storageBox = GetStorage();

  void startTimer(BuildContext context) {
    storageBox.writeIfNull(AppKeys.keyIsLoggedIn, false);
    storageBox.writeIfNull(AppKeys.keyIsOnboardingStarted, false);
    _timer = Timer(const Duration(seconds: 3), () => navigateToHome(context),);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  navigateToHome(BuildContext context) {
    storageBox.read(AppKeys.keyIsOnboardingStarted)
        ? storageBox.read(AppKeys.keyIsLoggedIn)
            ? Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard)
            : Navigator.of(context).pushReplacementNamed(AppRoutes.login)
        : Navigator.of(context).pushReplacementNamed(AppRoutes.onBoard);
  }
}
