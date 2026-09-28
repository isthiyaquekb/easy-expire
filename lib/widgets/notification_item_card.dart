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
  final lower = title.toLowerCase();
  if (lower.contains('expiry alert')) {
    return NotificationType.expiryAlert;
  }
  if (lower.contains('restock suggestion')) {
    return NotificationType.restockSuggestion;
  }
  if (lower.contains('system update')) {
    return NotificationType.systemUpdate;
  }
  if (lower.contains('delivery confirmed')) {
    return NotificationType.deliveryConfirmed;
  }
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 6.0,
      ), // Spacing between cards
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.borderColor,
          width: 1,
        ),
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
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.inputFillColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color:
                              isDark
                                  ? Colors.grey[300]
                                  : AppColors.bodyTextColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              body,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    isDark
                                        ? Colors.grey[400]
                                        : AppColors.bodyTextColor,
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
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              isDark
                                  ? Colors.grey[500]
                                  : AppColors.labelTextColor,
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
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Review Batch",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Dismiss Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onDismiss,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: theme.colorScheme.surface,
                              foregroundColor:
                                  isDark
                                      ? Colors.grey[300]
                                      : AppColors
                                          .notificationActionSecondaryText,
                              side: BorderSide(
                                color:
                                    isDark
                                        ? Colors.white24
                                        : AppColors
                                            .notificationActionSecondaryBorder,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Dismiss",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
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
