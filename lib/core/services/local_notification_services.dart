import 'dart:developer';
import 'package:easyexpire/core/constant/app_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationServices {
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final onClickNotification = BehaviorSubject<String>();

  //ON TAP ON ANY NOTIFICATION
  static void onTapNotification(NotificationResponse response) {
    onClickNotification.add(response.payload!);
  }

  // INITIALIZATION
  static Future init() async {
    tz.initializeTimeZones();
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (e) {
      log("Could not configure device local timezone: $e");
    }

    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: darwinInitializationSettings,
        );

    // request notification permissions
    try {
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      print("Error requesting Android notification permission: $e");
    }

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onTapNotification,
      onDidReceiveBackgroundNotificationResponse: onTapNotification,
    );
  }

  /// Darwin notification details for iOS alert, sound, and badge presentation
  static const DarwinNotificationDetails darwinNotificationDetails =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

  ///SIMPLE NOTIFICATION
  static Future showSimpleNotification(
    String title,
    String body,
    String payload, {
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          AppString.notificationChannelId,
          AppString.notificationChannelName,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
      macOS: darwinNotificationDetails,
    );
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  ///REPEATED NOTIFICATION
  static Future showRepeatedNotification(
    String title,
    String body,
    String payload, {
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          AppString.notificationChannelId,
          AppString.notificationChannelName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound("f1_notification"),
          ticker: 'ticker',
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    await flutterLocalNotificationsPlugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.everyMinute,
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  ///DAILY REPEATED NOTIFICATION
  static Future showDailyRepeatedNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          AppString.notificationChannelId,
          AppString.notificationChannelName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound("f1_notification"),
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    await flutterLocalNotificationsPlugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.daily,
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  ///HOURLY REPEATED NOTIFICATION
  static Future showHourlyRepeatedNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          AppString.notificationChannelId,
          AppString.notificationChannelName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound("f1_notification"),
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    await flutterLocalNotificationsPlugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.hourly,
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  ///SCHEDULED NOTIFICATION
  static Future showScheduleNotification(
    int hour,
    int minutes,
    String title,
    String body,
    String payload, {
    int id = 0,
  }) async {
    final scheduledDate = checkForTime(hour, minutes);
    await scheduleProductNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
    );
  }

  void onDidReceiveLocalNotification(
    BuildContext context,
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder:
          (BuildContext context) => CupertinoAlertDialog(
            title: Text(title ?? ''),
            content: Text(body ?? ''),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text('Ok'),
                onPressed: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  // await Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => SecondScreen(payload),
                  //   ),
                  // );
                },
              ),
            ],
          ),
    );
  }

  static Future showExpiryNotification({
    required int id,
    required String title,
    required String body,
    required DateTime expiryDate,
    required String payload,
  }) async {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      expiryDate.subtract(const Duration(days: 5)),
      tz.local,
    );

    // Skip if the notification would be in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          AppString.notificationChannelId,
          AppString.notificationChannelName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound("f1_notification"),
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, // unique ID
      title,
      body,
      scheduledDate,
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static tz.TZDateTime checkForTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduleTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduleTime.isBefore(now)) {
      scheduleTime = scheduleTime.add(const Duration(days: 5));
    }
    return scheduleTime;
  }

  /// Cancels a specific scheduled or active notification by [id].
  static Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      log("Cancelled notification ID: $id");
    } catch (e) {
      log("Error cancelling notification ID $id: $e");
    }
  }

  /// Cancels all pending and displayed notifications.
  static Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      log("Cancelled all notifications.");
    } catch (e) {
      log("Error cancelling all notifications: $e");
    }
  }

  /// Retrieves list of all pending scheduled notification requests.
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      log("Error retrieving pending notifications: $e");
      return [];
    }
  }

  /// Retrieves list of currently active (delivered to notification tray) notifications.
  static Future<List<ActiveNotification>> getActiveNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin.getActiveNotifications();
    } catch (e) {
      log("Error retrieving active notifications: $e");
      return [];
    }
  }

  /// Schedules a timezone-aware notification for a product at [scheduledDate].
  static Future<bool> scheduleProductNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    DateTime? referenceTime,
  }) async {
    try {
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      final currentNow =
          referenceTime != null
              ? tz.TZDateTime.from(referenceTime, tz.local)
              : tz.TZDateTime.now(tz.local);

      // Do not attempt to schedule in the past
      if (tzScheduledDate.isBefore(currentNow)) {
        log("Cannot schedule notification $id in the past: $tzScheduledDate");
        return false;
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            AppString.notificationChannelId,
            AppString.notificationChannelName,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound("f1_notification"),
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinNotificationDetails,
        macOS: darwinNotificationDetails,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      log("Successfully scheduled notification $id for $tzScheduledDate");
      return true;
    } catch (e) {
      log("Error scheduling notification $id: $e");
      return false;
    }
  }
}
