import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:easyexpire/widgets/notification_item_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:easyexpire/feature/notification/viewmodel/notification_viewmodel.dart';
import 'package:easyexpire/feature/home/viewmodel/home_viewmodel.dart';

// class NotificationPage extends StatefulWidget {
//   const NotificationPage({super.key});
//
//   @override
//   State<NotificationPage> createState() => _NotificationPageState();
// }
//
// class _NotificationPageState extends State<NotificationPage> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final homeVm = Provider.of<HomeViewModel>(context, listen: false);
//       final effectiveUserId =
//           homeVm.userId.isEmpty ? 'test_user_id' : homeVm.userId;
//       Provider.of<NotificationViewModel>(
//         context,
//         listen: false,
//       ).fetchNotifications(effectiveUserId);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBackground,
//       appBar: CommonAppBar(title: "Notification", isBack: false),
//       body: Consumer<NotificationViewModel>(
//         builder: (context, viewModel, child) {
//           if (viewModel.isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (viewModel.notifications.isEmpty) {
//             return const Center(child: Text("No notifications"));
//           }
//           return ListView.builder(
//             shrinkWrap: true,
//             itemCount: viewModel.notifications.length,
//             itemBuilder: (context, index) {
//               final notification = viewModel.notifications[index];
//               return Padding(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 8.0,
//                   horizontal: 16,
//                 ),
//                 child: Container(
//                   width: double.maxFinite,
//                   decoration: BoxDecoration(
//                     color: AppColors.primary,
//                     borderRadius: BorderRadius.circular(5),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8.0,
//                       vertical: 8.0,
//                     ),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 notification.title,
//                                 style: const TextStyle(
//                                   color: AppColors.primary,
//                                   fontFamily: 'Poppins',
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               Text(
//                                 notification.body,
//                                 style: const TextStyle(
//                                   color: AppColors.primary,
//                                   fontFamily: 'Poppins',
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w400,
//                                 ),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 4.0,
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       DateFormat(
//                                         'dd-MM-yyyy',
//                                       ).format(notification.timestamp),
//                                       style: const TextStyle(
//                                         color: AppColors.primary,
//                                         fontFamily: 'Poppins',
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.w400,
//                                       ),
//                                     ),
//                                     Text(
//                                       DateFormat(
//                                         'h:mm a',
//                                       ).format(notification.timestamp),
//                                       style: const TextStyle(
//                                         color: AppColors.primary,
//                                         fontFamily: 'Poppins',
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.w400,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.grey),
//                           onPressed: () {
//                             viewModel.deleteNotification(notification.id);
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// file: easy-expire/lib/feature/notification/view/notification_page.dart

import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:easyexpire/feature/notification/viewmodel/notification_viewmodel.dart';
import 'package:easyexpire/feature/home/viewmodel/home_viewmodel.dart'; // For userId


class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeVm = Provider.of<HomeViewModel>(context, listen: false);
      final effectiveUserId = homeVm.userId.isEmpty ? null : homeVm.userId;
      if(effectiveUserId!=null){
        Provider.of<NotificationViewModel>(context, listen: false).fetchNotifications(effectiveUserId);
      }
    });
  }

  // Helper to get date group text (Today, Yesterday, Date)
  String _getDateGroupText(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final notificationDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (notificationDate.isAtSameMomentAs(today)) {
      return 'TODAY';
    } else if (notificationDate.isAtSameMomentAs(yesterday)) {
      return 'YESTERDAY';
    } else {
      return DateFormat('EEEE, MMMM d').format(timestamp).toUpperCase(); // e.g., MONDAY, JANUARY 1
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: CommonAppBar(
        title: "Notifications",
        isBack: false, // Default false, but can be true if navigated to
        leading: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.primary),
          onPressed: () {
            // TODO: Implement "Clear All Notifications" logic
            // Provider.of<NotificationViewModel>(context, listen: false).clearAllNotifications();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primary),
            onPressed: () {
              // TODO: Implement search functionality for notifications
              print("Search notifications tapped!");
            },
          ),
        ],
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 80, color: AppColors.labelTextColor),
                  const SizedBox(height: 16),
                  Text(
                    "No notifications yet.",
                    style: TextStyle(color: AppColors.labelTextColor, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Group notifications by date
          final Map<String, List<NotificationModel>> groupedNotifications = {};
          for (var notification in viewModel.notifications) {
            final dateGroup = _getDateGroupText(notification.timestamp);
            if (!groupedNotifications.containsKey(dateGroup)) {
              groupedNotifications[dateGroup] = [];
            }
            groupedNotifications[dateGroup]!.add(notification);
          }

          // Sort date groups (e.g., Today, Yesterday, then oldest to newest)
          final sortedDateGroups = groupedNotifications.keys.toList();
          sortedDateGroups.sort((a, b) {
            if (a == 'TODAY') return -1;
            if (b == 'TODAY') return 1;
            if (a == 'YESTERDAY') return -1;
            if (b == 'YESTERDAY') return 1;
            // For other dates, sort by actual date
            final dateA = groupedNotifications[a]!.first.timestamp;
            final dateB = groupedNotifications[b]!.first.timestamp;
            return dateB.compareTo(dateA); // Newest date first
          });


          // Calculate unread alerts (assuming NotificationModel has an 'isRead' field)
          // If your NotificationModel doesn't have isRead, you'd need to add it
          final int unreadCount = viewModel.notifications.where((n) => !(n.isRead ?? false)).length;


          return RefreshIndicator(
            onRefresh: () async {
              final homeVm = Provider.of<HomeViewModel>(context, listen: false);
              final effectiveUserId = homeVm.userId.isEmpty ? 'test_user_id' : homeVm.userId;
              await viewModel.fetchNotifications(effectiveUserId);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                // Top info bar: unread alerts and "Mark all as read"
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'You have $unreadCount unread alerts.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.labelTextColor,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Implement "Mark all as read" logic
                          // viewModel.markAllAsRead();
                        },
                        child: Text(
                          "Mark all as read",
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Display grouped notifications
                ...sortedDateGroups.expand((dateGroup) {
                  final notificationsInGroup = groupedNotifications[dateGroup]!;
                  return [
                    // Date group header
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                      child: Text(
                        dateGroup,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.headlineTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    // List of notifications in this group
                    ...notificationsInGroup.map((notification) {
                      return NotificationItemCard(
                        notificationId: notification.id,
                        title: notification.title,
                        body: notification.body,
                        timestamp: notification.timestamp,
                        isRead: notification.isRead ?? false, // Use isRead if available in model
                        onReviewBatch: notification.title.toLowerCase().contains('expiry alert')
                            ? () {
                          print("Review Batch for ${notification.id}");
                          // TODO: Navigate to batch review screen
                        }
                            : null,
                        onDismiss: () {
                          print("Dismiss notification ${notification.id}");
                          // TODO: Implement dismiss/archive logic in ViewModel
                          viewModel.deleteNotification(notification.id); // Or a softer "dismiss"
                        },
                      );
                    }).toList(),
                  ];
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
