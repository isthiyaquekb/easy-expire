import 'dart:async';
import 'package:easyexpire/core/services/notification_history_service.dart';
import 'package:easyexpire/feature/notification/model/notification_model.dart';
import 'package:flutter/material.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationHistoryService _historyService;
  StreamSubscription<List<NotificationModel>>? _subscription;
  String? _currentUserId;

  NotificationViewModel({NotificationHistoryService? historyService})
    : _historyService = historyService ?? NotificationHistoryService();

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Starts listening to the Firestore stream of notifications for [userId]
  /// ordered by `updatedAt` descending.
  void listenToNotifications(String userId) {
    if (userId.isEmpty) {
      _subscription?.cancel();
      _subscription = null;
      _currentUserId = null;
      _notifications = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (_currentUserId == userId && _subscription != null) {
      return;
    }

    _subscription?.cancel();
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    _subscription = _historyService.streamNotifications(userId).listen(
      (items) {
        _notifications = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Compatibility method for manual fetching or pull-to-refresh.
  Future<void> fetchNotifications(String userId) async {
    listenToNotifications(userId);
  }

  /// Streams notifications directly for use with StreamBuilder if desired.
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _historyService.streamNotifications(userId);
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String userId, String productId) async {
    final effectiveUserId = userId.isNotEmpty ? userId : _currentUserId ?? '';
    if (effectiveUserId.isEmpty) return;

    // Optimistically update local state
    final index = _notifications.indexWhere((n) => n.productId == productId);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }

    await _historyService.markAsRead(
      userId: effectiveUserId,
      productId: productId,
    );
  }

  /// Marks all unread alerts for [userId] as read.
  Future<void> markAllAsRead(String userId) async {
    final effectiveUserId = userId.isNotEmpty ? userId : _currentUserId ?? '';
    if (effectiveUserId.isEmpty) return;

    // Optimistically update local state
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();

    await _historyService.markAllAsRead(userId: effectiveUserId);
  }

  /// Deletes a notification document from Firestore and local state.
  Future<void> deleteNotification(String userId, String productId) async {
    final effectiveUserId = userId.isNotEmpty ? userId : _currentUserId ?? '';
    if (effectiveUserId.isEmpty) return;

    _notifications.removeWhere((n) => n.productId == productId);
    notifyListeners();

    await _historyService.deleteNotification(
      userId: effectiveUserId,
      productId: productId,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
