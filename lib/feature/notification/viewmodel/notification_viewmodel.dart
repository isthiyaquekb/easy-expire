import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? 'Notification',
      body: data['body'] ?? '',
      timestamp:
          data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }
}

class NotificationViewModel extends ChangeNotifier {
  final CollectionReference _notificationsRef = FirebaseFirestore.instance
      .collection('notifications');

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();

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
