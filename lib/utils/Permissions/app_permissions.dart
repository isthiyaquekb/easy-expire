import 'dart:developer';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  static final _singleton = AppPermissions();
  static AppPermissions get instance => _singleton;

  // Permissions status
  PermissionStatus notificationPermissionStatus = PermissionStatus.denied;
  PermissionStatus cameraPermissionStatus = PermissionStatus.denied;

  // Checks whether permissions are granted
  bool isNotificationGranted = false;
  bool isCameraGranted = false;

  // Check the current notification permission status
  Future<bool> isNotificationPermissionCurrentlyGranted() async {
    final status = await Permission.notification.status;
    log("Current Permission Status Check: $status");
    if (status.isDenied) {
      requestNotificationPermission();
    }
    if (Platform.isIOS) {
      return status.isGranted;
    } else if (Platform.isAndroid) {
      return status.isGranted;
    }

    return true;
  }

  // Request notification permission
  Future<bool> requestNotificationPermission() async {
    PermissionStatus status;
    if (Platform.isIOS) {
      final localNotificationsPlugin = FlutterLocalNotificationsPlugin();
      final iosImplementation =
          localNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();

      if (iosImplementation != null) {
        // This call prompts the user. It does not return a direct grant/deny status from the prompt itself.
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        // IMPORTANT: After the prompt, we MUST re-check the actual status using permission_handler.
        // Add a small delay to allow the OS to update its status.
        await Future.delayed(const Duration(milliseconds: 500));
        // Now, check the actual status.
        final currentStatus = await Permission.notification.status;
        log("iOS Permission Status Check after prompt: $currentStatus");
        return currentStatus.isGranted;
      } else {
        log(
          "iOS implementation not available for flutterLocalNotificationsPlugin.",
        );
        // If plugin unavailable, fall back to permission_handler status check.
        return await isNotificationPermissionCurrentlyGranted();
      }
    } else if (Platform.isAndroid) {
      // Use permission_handler's request for Android. It returns status.
      status = await Permission.notification.request();
      log("Android Permission Status after request: $status");
      return status.isGranted;
    }
    // Default for other platforms or if permission is implicitly granted
    return true;
  }

  // Check and request notification permission
  Future<void> checkAndRequestNotificationPermission() async {
    await requestNotificationPermission();
  }

  // Check and request camera permission
  Future<void> checkAndRequestCameraPermission() async {
    cameraPermissionStatus = await Permission.camera.request();
    isCameraGranted = cameraPermissionStatus.isGranted;
  }

  // Check if all necessary permissions are granted
  Future<bool> checkAllPermissions() async {
    await checkAndRequestNotificationPermission();
    await checkAndRequestCameraPermission();

    // Here, you can add other permissions like storage, gallery, etc.
    return isNotificationGranted && isCameraGranted;
  }
}
