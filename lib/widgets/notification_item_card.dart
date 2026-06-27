// file: easy-expire/lib/common/widgets/notification_item_card.dart (create this file)

import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Enum to categorize notification types for styling and actions
enum NotificationType {
  expiryAlert,
  restockSuggestion,
  systemUpdate,
  deliveryConfirmed,
  general,
}

// Function to infer NotificationType from title (ideally, this would come from the model)
NotificationType _getNotificationType(String title) {
  if (title.toLowerCase().contains('expiry alert')) return NotificationType.expiryAlert;
  if (title.toLowerCase().contains('restock suggestion')) return NotificationType.restockSuggestion;
  if (title.toLowerCase().contains('system update')) return NotificationType.systemUpdate;
  if (title.toLowerCase().contains('delivery confirmed')) return NotificationType.deliveryConfirmed;
  return NotificationType.general;
}

class NotificationItemCard extends StatelessWidget {
  final String notificationId; // For deletion
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead; // Assuming you have this in your Notification model
  final VoidCallback? onReviewBatch; // Specific action for expiry alerts
  final VoidCallback? onDismiss; // Generic dismiss action
  final VoidCallback? onDelete; // For swipe-to-delete or specific delete button

  const NotificationItemCard({
    super.key,
    required this.notificationId,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false, // Default to unread for demonstration
    this.onReviewBatch,
    this.onDismiss,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final NotificationType type = _getNotificationType(title);
    Color borderColor;
    IconData icon;
    bool showActionButtons = false;

    switch (type) {
      case NotificationType.expiryAlert:
        borderColor = AppColors.notificationBorderUrgent;
        icon = Icons.warning_amber_rounded;
        showActionButtons = true;
        break;
      case NotificationType.restockSuggestion:
        borderColor = AppColors.notificationBorderGeneral;
        icon = Icons.trending_up;
        break;
      case NotificationType.systemUpdate:
        borderColor = AppColors.notificationBorderGeneral;
        icon = Icons.system_update_alt;
        break;
      case NotificationType.deliveryConfirmed:
        borderColor = AppColors.notificationBorderGeneral;
        icon = Icons.local_shipping_outlined;
        break;
      case NotificationType.general:
      default:
        borderColor = AppColors.notificationBorderGeneral;
        icon = Icons.info_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0), // Spacing between cards
      decoration: BoxDecoration(
        color: AppColors.notificationCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left border indicator
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notification Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.inputFillColor, // Light grey background
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: AppColors.bodyTextColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.headlineTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              body,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.bodyTextColor,
                                fontSize: 13,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Timestamp
                      Text(
                        DateFormat('h:mm a').format(timestamp),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.labelTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  // Action Buttons (only for certain notification types)
                  if (showActionButtons) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Review Batch Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onReviewBatch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.notificationActionPrimaryBg,
                              foregroundColor: AppColors.notificationActionPrimaryText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Review Batch",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Dismiss Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onDismiss,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.notificationCardBackground,
                              foregroundColor: AppColors.notificationActionSecondaryText,
                              side: const BorderSide(color: AppColors.notificationActionSecondaryBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Dismiss",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}