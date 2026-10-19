import 'package:cloud_firestore/cloud_firestore.dart';

/// In-app notification record stored at Users/{uid}/notifications/{productId}.
///
/// Guaranteed to have one document per product via upsert.
class NotificationModel {
  final int notificationId;
  final String productId;
  final String productName;
  final String batchId;
  final int daysRemaining;
  final String category; // 'warning' | 'urgent' | 'expired'
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int notifyCount;
  bool isRead;

  NotificationModel({
    int? notificationId,
    String? productId,
    String? id,
    String? productName,
    String? batchId,
    int? daysRemaining,
    String? category,
    required this.title,
    required this.body,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? timestamp,
    this.notifyCount = 1,
    this.isRead = false,
  })  : notificationId = notificationId ?? 0,
        productId = productId ?? id ?? '',
        productName = productName ?? '',
        batchId = batchId ?? '',
        daysRemaining = daysRemaining ?? 0,
        category = category ?? 'warning',
        createdAt = createdAt ?? updatedAt ?? timestamp ?? DateTime.now(),
        updatedAt = updatedAt ?? timestamp ?? createdAt ?? DateTime.now();

  /// Compatibility getters for existing UI components
  String get id => productId;
  DateTime get timestamp => updatedAt;

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDateTime(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    final updated = parseDateTime(
      data['updatedAt'] ?? data['timestamp'],
      DateTime.now(),
    );
    final created = parseDateTime(data['createdAt'], updated);

    return NotificationModel(
      notificationId:
          data['notificationId'] is int ? data['notificationId'] as int : 0,
      productId: (data['productId'] as String?)?.isNotEmpty == true
          ? data['productId'] as String
          : doc.id,
      productName: data['productName'] as String? ?? '',
      batchId: data['batchId'] as String? ?? '',
      daysRemaining:
          data['daysRemaining'] is int ? data['daysRemaining'] as int : 0,
      category: data['category'] as String? ?? 'warning',
      title: data['title'] as String? ?? 'Product Expiry Alert',
      body: data['body'] as String? ?? '',
      createdAt: created,
      updatedAt: updated,
      notifyCount:
          data['notifyCount'] is int ? data['notifyCount'] as int : 1,
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'notificationId': notificationId,
    'productId': productId,
    'productName': productName,
    'batchId': batchId,
    'daysRemaining': daysRemaining,
    'category': category,
    'title': title,
    'body': body,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'notifyCount': notifyCount,
    'isRead': isRead,
  };
}
