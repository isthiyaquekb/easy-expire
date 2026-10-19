import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// In-memory notification state tracker for mock channels in tests.
class MockNotificationState {
  static final Map<int, Map<String, dynamic>> pendingMap = {};
  static final List<Map<String, dynamic>> shownNotifications = [];

  static void reset() {
    pendingMap.clear();
    shownNotifications.clear();
  }
}

void setupTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  MockNotificationState.reset();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.UTC);

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
          return MockNotificationState.pendingMap.values
              .map((map) => Map<String, dynamic>.from(map))
              .toList();
        } else if (methodCall.method == 'zonedSchedule' ||
            methodCall.method == 'schedule' ||
            methodCall.method == 'show') {
          final args = Map<String, dynamic>.from(
            methodCall.arguments as Map<dynamic, dynamic>,
          );
          final id = args['id'] as int;
          if (methodCall.method == 'show') {
            MockNotificationState.shownNotifications.add(args);
          } else {
            MockNotificationState.pendingMap[id] = {
              'id': id,
              'title': args['title'] ?? '',
              'body': args['body'] ?? '',
              'payload': args['payload'] ?? '',
            };
          }
          return null;
        } else if (methodCall.method == 'cancel') {
          int? id;
          if (methodCall.arguments is int) {
            id = methodCall.arguments as int;
          } else if (methodCall.arguments is Map) {
            id = (methodCall.arguments as Map)['id'] as int?;
          }
          if (id != null) {
            MockNotificationState.pendingMap.remove(id);
          }
          return null;
        } else if (methodCall.method == 'cancelAll') {
          MockNotificationState.pendingMap.clear();
          return null;
        }
        return null;
      });

  const MethodChannel timezoneChannel = MethodChannel('flutter_timezone');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(timezoneChannel, (MethodCall methodCall) async {
        return 'UTC';
      });
}
