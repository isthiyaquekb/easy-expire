import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/feature/notification/model/notification_model.dart';
import 'package:flutter/material.dart';

class NotificationViewModel extends ChangeNotifier {
  final CollectionReference _notificationsRef = FirebaseFirestore.instance
      .collection('notifications');

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications(String userId) async {
    if (userId.isEmpty) {
      _notifications = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      try {
        final querySnapshot =
            await _notificationsRef
                .where('user_id', isEqualTo: userId)
                .orderBy('timestamp', descending: true)
                .get();

        _notifications =
            querySnapshot.docs
                .map((doc) => NotificationModel.fromFirestore(doc))
                .toList();
      } catch (indexError) {
        log(
          "Composite index missing or query error, attempting unindexed query fallback: $indexError",
        );
        final querySnapshot =
            await _notificationsRef.where('user_id', isEqualTo: userId).get();

        _notifications =
            querySnapshot.docs
                .map((doc) => NotificationModel.fromFirestore(doc))
                .toList();
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }

      log("Fetched ${_notifications.length} notifications.");
    } catch (e) {
      log("Error fetching notifications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
      _notifications.removeWhere((element) => element.id == notificationId);
      notifyListeners();
      log("Successfully deleted notification: $notificationId");
    } catch (e) {
      log("Error deleting notification: $e");
      throw Exception("Failed to delete notification");
    }
  }
}
