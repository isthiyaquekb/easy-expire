import 'dart:io';
import 'package:easyexpire/core/services/local_notification_services.dart';
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
    if (Platform.isIOS) {
      // On iOS, use your internal flag or assume granted after request
      return isNotificationGranted;
    } else if (Platform.isAndroid && Platform.version.contains('13')) {
      final status = await Permission.notification.status;
      notificationPermissionStatus = status;
      isNotificationGranted = status.isGranted;
      return isNotificationGranted;
    } else {
      return true;
    }
  }


  // Request notification permission
  Future<void> requestNotificationPermission() async {
    if(Platform.isIOS){
      await LocalNotificationServices.flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }else {
      // Only for Android 13+ (API 33)
      final status = await Permission.notification.request();
      notificationPermissionStatus = status;
      isNotificationGranted = status.isGranted;
    }
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
