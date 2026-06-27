import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/core/services/local_notification_services.dart';
import 'package:easyexpire/feature/inventory/model/inventory_model.dart';
import 'package:easyexpire/utils/Formatter/app_date_formatter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      log("Background task started: $task");
      // 1. Initialize Firebase for the background isolate
      await Firebase.initializeApp();

      // 2. Initialize Notifications
      await LocalNotificationServices.init();

      // Ensure we have a user ID passed in inputData
      if (inputData == null || !inputData.containsKey('userId')) {
        log("No userId provided to background task.");
        return true;
      }
      final userId = inputData['userId'] as String;

      if (task == 'triggerTestNotification') {
        // Special case for manual testing
        await _handleTestNotification(userId);
        return true;
      }

      // 3. Query all products for this user
      final snapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .where('user_id', isEqualTo: userId)
              .get();

      final productList =
          snapshot.docs.map((doc) {
            return InventoryModel.fromMap(doc.data());
          }).toList();

      // 4. Check expiry dates and trigger notifications + firestore logging
      for (int i = 0; i < productList.length; i++) {
        final product = productList[i];
        final dateStr = AppDateFormatter.dateTimeFromFirebase(
          product.expiryDate,
        );
        final expiryDate = DateFormat("dd-MM-yyyy").parse(dateStr);
        final now = DateTime.now();

        final daysLeft =
            DateTime(
              expiryDate.year,
              expiryDate.month,
              expiryDate.day,
            ).difference(DateTime(now.year, now.month, now.day)).inDays;

        if (daysLeft <= 5 && daysLeft > 0) {
          // Log daily
          await LocalNotificationServices.showSimpleNotification(
            'Product Expiry Alert',
            '${product.productName} will expire in $daysLeft days!',
            product.userId,
          );
          await _logNotificationToFirestore(
            title: 'Product Expiry Alert',
            body: '${product.productName} will expire in $daysLeft days!',
            userId: product.userId,
          );
        } else if (daysLeft == 0) {
          // Log heavily on the exact day
          await LocalNotificationServices.showSimpleNotification(
            'Product Expires TODAY',
            '${product.productName} is expiring today!',
            product.userId,
          );
          await _logNotificationToFirestore(
            title: 'Product Expires TODAY',
            body: '${product.productName} is expiring today!',
            userId: product.userId,
          );
        }
      }

      log("Background task completed successfully.");
      return true;
    } catch (err) {
      log("Background task failed: $err");
      // throw Exception(err); return true to prevent endless retries for now
      return true;
    }
  });
}

Future<void> _handleTestNotification(String userId) async {
  final testTitle = 'Background Test Alert';
  final testBody = 'This is a test notification injected from the background!';

  await LocalNotificationServices.showSimpleNotification(
    testTitle,
    testBody,
    userId,
  );

  await _logNotificationToFirestore(
    title: testTitle,
    body: testBody,
    userId: userId,
  );
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
    log("Background notification logged to Firestore");
  } catch (e) {
    log("Error logging background notification: $e");
  }
}

class BackgroundService {
  static const String periodicTaskName = "checkExpiryDates";
  static const String testTaskName = "triggerTestNotification";

  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode:
          true, // If enabled it will post a notification whenever the task is running
    );
  }

  static void registerPeriodicExpiryCheck(String userId) {
    Workmanager().registerPeriodicTask(
      "1", // unique id
      periodicTaskName,
      inputData: {'userId': userId},
      frequency: const Duration(hours: 1), // Minimum is 15 minutes
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static void triggerOneOffTest(String userId) {
    Workmanager().registerOneOffTask(
      "2",
      testTaskName,
      inputData: {'userId': userId},
    );
  }
}
