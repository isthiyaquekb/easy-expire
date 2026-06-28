import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/core/constant/app_theme.dart';
import 'package:easyexpire/core/services/firebase_services.dart';
import 'package:easyexpire/core/services/local_notification_services.dart';
import 'package:easyexpire/feature/dashboard/viewmodel/dashboard_provider.dart';
import 'package:easyexpire/feature/home/viewmodel/home_viewmodel.dart';
import 'package:easyexpire/feature/inventory/view_model/inventory_view_model.dart';
import 'package:easyexpire/feature/login/viewmodel/auth_viewmodel.dart';
import 'package:easyexpire/feature/onboard/view_model/onboarding_view_model.dart';
import 'package:easyexpire/feature/profile/viewmodel/profile_viewmodel.dart';
import 'package:easyexpire/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:easyexpire/feature/splash/view_model/splash_provider.dart';
import 'package:easyexpire/feature/notification/viewmodel/notification_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

import 'package:easyexpire/core/services/background_service.dart';
import 'package:toastification/toastification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await FirebaseServices().initializeFirebase();
  await LocalNotificationServices.init();
  await BackgroundService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => OnboardingViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => InventoryViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewmodel()),
        ChangeNotifierProvider(create: (_) => SettingsViewmodel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'Easy Expire',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generatedRoutes,
      ),
    );
  }
}
