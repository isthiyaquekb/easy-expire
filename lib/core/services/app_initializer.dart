import 'dart:developer';
import 'package:easyexpire/core/services/background_service.dart';
import 'package:easyexpire/core/services/fcm_service.dart';
import 'package:easyexpire/core/services/firebase_services.dart';
import 'package:easyexpire/core/services/local_notification_services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class AppInitResult {
  final bool isFirebaseReady;
  final bool isStorageReady;
  final bool isNotificationsReady;
  final String? errorMessage;

  const AppInitResult({
    required this.isFirebaseReady,
    required this.isStorageReady,
    required this.isNotificationsReady,
    this.errorMessage,
  });
}

class AppInitializer {
  static bool isFirebaseReady = false;
  static bool isStorageReady = false;
  static bool isNotificationsReady = false;
  static String? startupError;

  static Future<AppInitResult> initialize({
    Duration storageTimeout = const Duration(seconds: 4),
    Duration firebaseTimeout = const Duration(seconds: 8),
    Duration optionalServiceTimeout = const Duration(seconds: 4),
    void Function(String? payload)? onNotificationNavigation,
  }) async {
    // 1. GetStorage local storage
    try {
      await GetStorage.init().timeout(storageTimeout);
      isStorageReady = true;
    } catch (e, stack) {
      log('[STARTUP] Warning: GetStorage.init failed or timed out: $e\n$stack');
      isStorageReady = false;
    }

    // 2. Firebase Core initialization
    String? firebaseErr;
    try {
      await FirebaseServices().initializeFirebase().timeout(firebaseTimeout);
      isFirebaseReady = true;
      startupError = null;
      log('[STARTUP] Firebase initialized successfully.');
    } catch (e, stack) {
      firebaseErr = e.toString();
      startupError = firebaseErr;
      isFirebaseReady = false;
      log('[STARTUP] CRITICAL: Firebase initialisation failed or timed out: $e\n$stack');
    }

    // 3. Local notification daemon
    bool notifsReady = false;
    try {
      await LocalNotificationServices.init().timeout(optionalServiceTimeout);
      notifsReady = true;
      isNotificationsReady = true;
    } catch (e) {
      log('[STARTUP] Warning: LocalNotificationServices.init failed or timed out: $e');
    }

    // 4. Background Service (WorkManager)
    try {
      await BackgroundService.initialize().timeout(optionalServiceTimeout);
    } catch (e) {
      log('[STARTUP] Warning: BackgroundService.initialize failed: $e');
    }

    // 5. FCM Push Service (only if Firebase is ready)
    if (isFirebaseReady) {
      try {
        await FcmService().initialize(
          onNotificationTap: (RemoteMessage message) {
            log('[NOTIF] FCM tap handler received: ${message.data}');
            final payload = message.data['payload'] ?? message.data['category'];
            onNotificationNavigation?.call(payload is String ? payload : null);
          },
        ).timeout(optionalServiceTimeout);
      } catch (e) {
        log('[STARTUP] Warning: FcmService initialization failed: $e');
      }
    }

    return AppInitResult(
      isFirebaseReady: isFirebaseReady,
      isStorageReady: isStorageReady,
      isNotificationsReady: notifsReady,
      errorMessage: firebaseErr,
    );
  }
}
