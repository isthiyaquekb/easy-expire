import 'dart:async';
import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/core/constant/expiry_policy.dart';
import 'package:easyexpire/core/services/notification_history_service.dart';
import 'package:easyexpire/feature/dashboard/viewmodel/dashboard_provider.dart';
import 'package:easyexpire/feature/home/viewmodel/home_viewmodel.dart';
import 'package:easyexpire/feature/notification/model/notification_model.dart';
import 'package:easyexpire/feature/notification/viewmodel/notification_viewmodel.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  Timer? _relativeTimeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeVm = Provider.of<HomeViewModel>(context, listen: false);
      final effectiveUserId = homeVm.userId;
      if (effectiveUserId.isNotEmpty) {
        Provider.of<NotificationViewModel>(
          context,
          listen: false,
        ).listenToNotifications(effectiveUserId);
      }
    });

    // Periodically trigger a rebuild every minute to refresh relative timestamps ("just now", "3 mins ago")
    // without re-querying Firestore.
    _relativeTimeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _relativeTimeTimer?.cancel();
    super.dispose();
  }

  Widget _buildBadge(NotificationModel notification) {
    Color bgColor;
    Color textColor;
    String label;

    final days = notification.daysRemaining;
    if (notification.category == 'expired' || ExpiryPolicy.isExpired(days)) {
      bgColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
      label = 'EXPIRED';
    } else if (notification.category == 'urgent' || ExpiryPolicy.isUrgent(days)) {
      bgColor = const Color(0xFFFEE8E6);
      textColor = const Color(0xFFD32F2F);
      label = 'EXPIRES TODAY';
    } else {
      bgColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFE65100);
      label = days == 1 ? '1 DAY LEFT' : '$days DAYS LEFT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = Provider.of<HomeViewModel>(context);
    final effectiveUserId = homeVm.userId;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CommonAppBar(
        title: "Notifications",
        isBack: false,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Image(image: AssetImage(AppAssets.appLogo)),
        ),
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: AppColors.labelTextColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No notifications yet.",
                    style: TextStyle(
                      color: AppColors.labelTextColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = viewModel.notifications;
          final unreadCount = viewModel.unreadCount;

          return RefreshIndicator(
            onRefresh: () async {
              if (effectiveUserId.isNotEmpty) {
                await viewModel.fetchNotifications(effectiveUserId);
              }
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                // Top header: unread alerts count and "Mark all as read" button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        unreadCount > 0
                            ? 'You have $unreadCount unread alert${unreadCount > 1 ? 's' : ''}.'
                            : 'All caught up!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.labelTextColor,
                          fontSize: 14,
                        ),
                      ),
                      if (unreadCount > 0)
                        TextButton(
                          onPressed: () {
                            viewModel.markAllAsRead(effectiveUserId);
                          },
                          child: Text(
                            "Mark all as read",
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Notification list items with swipe-to-dismiss
                ...notifications.map((notification) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final relativeTime =
                      NotificationHistoryService.formatRelativeTime(
                        notification.updatedAt,
                      );

                  return Dismissible(
                    key: Key(notification.productId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.delete_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Delete",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onDismissed: (_) {
                      viewModel.deleteNotification(
                        effectiveUserId,
                        notification.productId,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Removed alert for ${notification.productName.isNotEmpty ? notification.productName : "product"}',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isDark ? Colors.white12 : AppColors.borderColor,
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Mark as read and route user
                          viewModel.markAsRead(
                            effectiveUserId,
                            notification.productId,
                          );

                          final dashboardVm = Provider.of<DashboardProvider>(
                            context,
                            listen: false,
                          );
                          if (notification.category == 'urgent') {
                            dashboardVm.changeBottomNavIndex(0); // Home tab
                          } else {
                            homeVm.setSelectedFilter(
                              ExpiryPolicy.warningWindowDays,
                            );
                            dashboardVm.changeBottomNavIndex(1); // Products tab
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Unread indicator dot
                                  if (!notification.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    ),
                                  // Product name / title
                                  Expanded(
                                    child: Text(
                                      notification.productName.isNotEmpty
                                          ? notification.productName
                                          : notification.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight:
                                            notification.isRead
                                                ? FontWeight.w500
                                                : FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Days remaining badge
                                  _buildBadge(notification),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Notification body
                              Text(
                                notification.body,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color:
                                      isDark
                                          ? Colors.grey[400]
                                          : AppColors.bodyTextColor,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Relative timestamp and batch details
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (notification.batchId.isNotEmpty)
                                    Text(
                                      'Batch: ${notification.batchId}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall?.copyWith(
                                        color:
                                            isDark
                                                ? Colors.grey[500]
                                                : AppColors.labelTextColor,
                                        fontSize: 11,
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  Text(
                                    relativeTime,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall?.copyWith(
                                      color:
                                          isDark
                                              ? Colors.grey[500]
                                              : AppColors.labelTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
