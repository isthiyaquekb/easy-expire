import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/core/services/local_notification_services.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:easyexpire/core/services/product_notification_coordinator.dart';
import 'package:easyexpire/core/utils/expiry_date_calculator.dart';
import 'package:easyexpire/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get_storage/get_storage.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final startTime = DateTime.now();
    log(
      '[NOTIF] Background task "$task" started at ${startTime.toIso8601String()}',
    );

    try {
      // 1. Initialize Firebase for the background isolate with platform options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Initialize local storage
      await GetStorage.init();

      // 3. Initialize Timezones inside the background isolate
      tz.initializeTimeZones();
      try {
        final currentTimeZone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
        log('[NOTIF] Background isolate timezone set to: $currentTimeZone');
      } catch (tzErr) {
        log(
          '[NOTIF] Warning: Could not detect device timezone in background isolate: $tzErr',
        );
      }

      // 4. Initialize Local Notifications
      await LocalNotificationServices.init();

      // 5. Resolve user ID: try inputData -> GetStorage -> FirebaseAuth
      String? userId = inputData?['userId'] as String?;
      if (userId == null || userId.isEmpty) {
        userId = GetStorage().read<String>('saved_user_id');
        log('[NOTIF] Background fallback: read userId from GetStorage ($userId)');
      }
      if (userId == null || userId.isEmpty) {
        userId = FirebaseAuth.instance.currentUser?.uid;
        log(
          '[NOTIF] Background fallback: read userId from FirebaseAuth ($userId)',
        );
      }

      if (userId == null || userId.isEmpty) {
        log(
          '[NOTIF] Background task aborted: No userId provided or discoverable.',
        );
        return true;
      }

      // Persist resolved userId for subsequent runs
      await GetStorage().write('saved_user_id', userId);

      if (task == 'triggerTestNotification') {
        // Special case for manual diagnostics
        await _handleTestNotification(userId);
        return true;
      }

      // 6. Query products for this user
      final snapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .where('user_id', isEqualTo: userId)
              .get();

      final productList =
          snapshot.docs.map((doc) {
            return InventoryModel.fromMap(doc.data(), docId: doc.id);
          }).toList();

      log(
        '[NOTIF] Background task loaded ${productList.length} products for user: $userId',
      );

      // 7. Check expiry dates and deliver category digests via coordinator
      final coordinator = ProductNotificationCoordinator();
      final sentCount = await coordinator.processPeriodicBackgroundCheck(
        productList,
        logToFirestore: _logNotificationToFirestore,
      );

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      log(
        '[NOTIF] Background task "$task" completed in ${elapsed}ms ($sentCount digests sent).',
      );
      return true;
    } catch (err, stackTrace) {
      log('[NOTIF] Background task "$task" failed: $err\n$stackTrace');
      return true;
    }
  });
}

Future<void> _handleTestNotification(String userId) async {
  final testTitle = 'Background Test Alert';
  final testBody = 'This is a test notification injected from the background!';
  final notifId = generateStableNotificationId('test_alert_$userId');

  await LocalNotificationServices.showSimpleNotification(
    testTitle,
    testBody,
    'dashboard_urgent',
    id: notifId,
  );

  await _logNotificationToFirestore(
    title: testTitle,
    body: testBody,
    userId: userId,
  );
  log('[NOTIF] Test background notification delivered (ID: $notifId)');
}

Future<void> _logNotificationToFirestore({
  required String title,
  required String body,
  required String userId,
}) async {
  try {
    if (userId.isEmpty) return;
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'body': body,
      'user_id': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    log('[NOTIF] Notification logged to Firestore for user: $userId');
  } catch (e) {
    log('[NOTIF] Error logging notification to Firestore: $e');
  }
}

class BackgroundService {
  static const String periodicTaskName = "checkExpiryDates";
  static const String testTaskName = "triggerTestNotification";

  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
    log('[NOTIF] BackgroundService initialized.');
  }

  static void registerPeriodicExpiryCheck(String userId) {
    // Persist user ID locally so the background isolate always has access
    GetStorage().write('saved_user_id', userId);

    Workmanager().registerPeriodicTask(
      "1", // unique id
      periodicTaskName,
      inputData: {'userId': userId},
      frequency: const Duration(hours: 1), // Minimum periodic interval
      constraints: Constraints(networkType: NetworkType.connected),
    );
    log(
      '[NOTIF] Registered periodic background expiry check for user: $userId',
    );
  }

  static void triggerOneOffTest(String userId) {
    GetStorage().write('saved_user_id', userId);

    Workmanager().registerOneOffTask(
      "2",
      testTaskName,
      inputData: {'userId': userId},
    );
    log('[NOTIF] Triggered one-off background test for user: $userId');
  }
}
