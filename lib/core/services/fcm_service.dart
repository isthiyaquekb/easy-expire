import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/core/constant/app_keys.dart';
import 'package:easyexpire/core/services/local_notification_services.dart';
import 'package:easyexpire/core/services/product_notification_coordinator.dart';
import 'package:easyexpire/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get_storage/get_storage.dart';

/// Top-level background handler executed in background isolate when an FCM message arrives.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  log('[NOTIF] Background FCM message received: ${message.messageId}, data: ${message.data}');
}

/// Manages FCM token registration, foreground/background message handling,
/// token refresh, and deduplication against Layer A local digests.
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  FirebaseMessaging? _messaging;
  FirebaseMessaging get messaging => _messaging ??= FirebaseMessaging.instance;

  FirebaseFirestore? _firestore;
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  FirebaseAuth? _auth;
  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;

  final GetStorage _storage = GetStorage();

  bool _initialized = false;

  /// Initializes FCM permissions, listeners, and token registration.
  Future<void> initialize({
    void Function(RemoteMessage message)? onNotificationTap,
  }) async {
    if (_initialized) return;
    _initialized = true;

    // 1. Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request notification permissions
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    log('[NOTIF] FCM notification authorization status: ${settings.authorizationStatus}');

    // 3. On iOS, wait for APNs token before requesting FCM token
    if (Platform.isIOS) {
      try {
        final apnsToken = await messaging.getAPNSToken();
        log('[NOTIF] iOS APNs token: $apnsToken');
      } catch (apnsErr) {
        log('[NOTIF] Error fetching APNs token: $apnsErr');
      }
    }

    // 4. Retrieve and register initial FCM token
    try {
      final token = await messaging.getToken();
      if (token != null) {
        log('[NOTIF] FCM Token retrieved: $token');
        await _saveFcmTokenLocallyAndRemotely(token);
      }
    } catch (e) {
      log('[NOTIF] Error getting FCM token: $e');
    }

    // 5. Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      log('[NOTIF] FCM Token refreshed: $newToken');
      await _saveFcmTokenLocallyAndRemotely(newToken);
    });

    // 6. Handle foreground push notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      log('[NOTIF] Foreground FCM message received: ${message.messageId}, title: ${message.notification?.title}');

      final notification = message.notification;
      final data = message.data;
      final title = notification?.title ?? data['title'] ?? 'Product Expiry Alert';
      final body = notification?.body ?? data['body'] ?? '';
      final payload = data['payload'] ?? data['category'] ?? 'dashboard_urgent';

      // Show local notification since iOS does not present banners in foreground by default
      final notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await LocalNotificationServices.showSimpleNotification(
        title,
        body,
        payload,
        id: notifId,
      );

      // Dedupe against Layer A: cancel today's pending local digest and mark delivered
      final today = DateTime.now();
      await ProductNotificationCoordinator().cancelTodayLocalDigest(today);
      log('[NOTIF] Foreground FCM push processed and today local digest cancelled.');
    });

    // 7. Handle notification taps when app is in background (but running)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('[NOTIF] Notification tapped from background: ${message.data}');
      if (onNotificationTap != null) {
        onNotificationTap(message);
      }
    });

    // 8. Handle notification tap that launched app from terminated state
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      log('[NOTIF] App launched from terminated state via FCM notification: ${initialMessage.data}');
      if (onNotificationTap != null) {
        onNotificationTap(initialMessage);
      }
    }
  }

  /// Persists token in GetStorage and synchronizes to Users/{uid} in Firestore.
  Future<void> _saveFcmTokenLocallyAndRemotely(String token) async {
    await _storage.write(AppKeys.keyFcmToken, token);

    final user = auth.currentUser;
    if (user == null || user.uid.isEmpty) {
      log('[NOTIF] No active Firebase user; stored FCM token locally for post-login sync.');
      return;
    }

    await syncTokenToFirestore(user.uid, token);
  }

  /// Synchronizes FCM token and device timezone to Firestore `Users/{uid}` doc.
  Future<void> syncTokenToFirestore(String userId, [String? explicitToken]) async {
    try {
      final token = explicitToken ?? _storage.read<String>(AppKeys.keyFcmToken);
      if (token == null || token.isEmpty) {
        log('[NOTIF] syncTokenToFirestore: No token available.');
        return;
      }

      String userTimezone = 'UTC';
      try {
        userTimezone = await FlutterTimezone.getLocalTimezone();
      } catch (tzErr) {
        log('[NOTIF] Could not resolve timezone: $tzErr');
      }

      await _storage.write(AppKeys.keyTimezone, userTimezone);

      final userRef = firestore.collection('Users').doc(userId);
      await userRef.set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'timezone': userTimezone,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      log('[NOTIF] Synced FCM token and timezone ($userTimezone) to Users/$userId');
    } catch (e) {
      log('[NOTIF] Error syncing FCM token to Firestore: $e');
    }
  }

  /// Unregisters FCM token on user logout.
  Future<void> onLogout(String userId) async {
    try {
      final token = _storage.read<String>(AppKeys.keyFcmToken);
      if (token != null && token.isNotEmpty && userId.isNotEmpty) {
        await firestore.collection('Users').doc(userId).set({
          'fcmTokens': FieldValue.arrayRemove([token]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        log('[NOTIF] Removed FCM token from Users/$userId on logout');
      }

      await messaging.deleteToken();
      await _storage.remove(AppKeys.keyFcmToken);
      log('[NOTIF] FCM token deleted locally');
    } catch (e) {
      log('[NOTIF] Error during FCM logout cleanup: $e');
    }
  }
}
