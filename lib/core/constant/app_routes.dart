import 'package:easyexpire/feature/dashboard/view/dashboard.dart';
import 'package:easyexpire/feature/home/view/home_page.dart';
import 'package:easyexpire/feature/inventory/view/inventory_page.dart';
import 'package:easyexpire/feature/login/view/login_page.dart';
import 'package:easyexpire/feature/login/view/signup_page.dart';
import 'package:easyexpire/feature/onboard/view/onboarding_screen.dart';
import 'package:easyexpire/feature/profile/view/edit_profile_page.dart';
import 'package:easyexpire/feature/settings/view/ringtone_selection_page.dart';
import 'package:easyexpire/feature/settings/view/settings_page.dart';
import 'package:easyexpire/feature/splash/view/splash_screen.dart';
import 'package:flutter/material.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const onBoard = '/on-board';
  static const dashboard = '/dashboard';
  static const home = '/home';
  static const login = '/login';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const scanner = '/scanner';
  static const seeAll = '/see-all';
  static const search = '/search';
  static const permission = '/permission';
  static const inventory = '/inventory';
  static const editProfile = '/edit-profile';
  static const settings = '/settings';
  static const ringtoneSelection = '/ringtone-selection';


  static Route<dynamic> generatedRoutes(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (context) => const SplashScreen());

      case onBoard:
        return MaterialPageRoute(builder: (context) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (context) => const LoginPage());
      case signUp:
        return MaterialPageRoute(builder: (context) => const SignupPage());
      case dashboard:
        return MaterialPageRoute(builder: (context) => const Dashboard());
      case home:
        return MaterialPageRoute(builder: (context) => const HomePage());

      case inventory:return MaterialPageRoute(builder: (context) => const InventoryPage());
      case editProfile:return MaterialPageRoute(builder: (context) => const EditProfilePage());
      case settings:return MaterialPageRoute(builder: (context) => const SettingsPage());
      case ringtoneSelection:return MaterialPageRoute(builder: (context) => const RingtoneSelectionPage());

      default:
        throw const FormatException("Route not found!, check routes again");
    }
  }
}
