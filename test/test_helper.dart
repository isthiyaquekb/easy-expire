import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void setupTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register platform-specific implementation matching the test host
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    MacOSFlutterLocalNotificationsPlugin.registerWith();
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    IOSFlutterLocalNotificationsPlugin.registerWith();
  }

  // Provide an isolated temp directory per test suite to prevent GetStorage file-lock collisions
  final tempDir = Directory.systemTemp.createTempSync('easy_expire_test_');
  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, (
        MethodCall methodCall,
      ) async {
        return tempDir.path;
      });

  const MethodChannel notifChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(notifChannel, (MethodCall methodCall) async {
        if (methodCall.method == 'pendingNotificationRequests') {
          return <Map<String, dynamic>>[];
        }
        return null;
      });

  const MethodChannel timezoneChannel = MethodChannel('flutter_timezone');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(timezoneChannel, (MethodCall methodCall) async {
        return 'UTC';
      });
}
