import 'dart:async';
import 'dart:developer';
import 'package:easyexpire/core/constant/expiry_policy.dart';
import 'package:easyexpire/core/services/local_notification_services.dart';
import 'package:easyexpire/core/services/notification_history_service.dart';
import 'package:easyexpire/feature/dashboard/viewmodel/dashboard_provider.dart';
import 'package:easyexpire/feature/home/view/home_page.dart';
import 'package:easyexpire/feature/home/viewmodel/home_viewmodel.dart';
import 'package:easyexpire/feature/inventory/view/add_new_product_screen.dart';
import 'package:easyexpire/feature/inventory/view/inventory_page.dart';
import 'package:easyexpire/feature/notification/view/notification_page.dart';
import 'package:easyexpire/feature/notification/viewmodel/notification_viewmodel.dart';
import 'package:easyexpire/feature/profile/view/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  StreamSubscription<String>? _notificationSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial sync of delivered notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncActiveNotifications();
      final homeVm = Provider.of<HomeViewModel>(context, listen: false);
      if (homeVm.userId.isNotEmpty) {
        Provider.of<NotificationViewModel>(
          context,
          listen: false,
        ).listenToNotifications(homeVm.userId);
      }
    });

    // Handle tapping digest notifications to navigate to appropriate section
    _notificationSub = LocalNotificationServices.onClickNotification.listen((
      payload,
    ) {
      if (!mounted) return;
      final dashboardVm = Provider.of<DashboardProvider>(
        context,
        listen: false,
      );
      final homeVm = Provider.of<HomeViewModel>(context, listen: false);

      if (payload == 'dashboard_urgent') {
        dashboardVm.changeBottomNavIndex(0); // Home with Urgent Attention
      } else if (payload == 'warning_attention') {
        homeVm.setSelectedFilter(ExpiryPolicy.warningWindowDays);
        dashboardVm.changeBottomNavIndex(1); // Filtered product list
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncActiveNotifications();
    }
  }

  Future<void> _syncActiveNotifications() async {
    try {
      final homeVm = Provider.of<HomeViewModel>(context, listen: false);
      final userId = homeVm.userId;
      if (userId.isEmpty) return;

      final active = await LocalNotificationServices.getActiveNotifications();
      if (active.isNotEmpty) {
        await NotificationHistoryService().syncDeliveredNotifications(
          userId: userId,
          activeNotifications: active,
        );
      }
    } catch (e) {
      log('[NOTIF] Could not sync active notifications: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<DashboardProvider>(
        builder:
            (context, provider, child) => IndexedStack(
              index: provider.currentIndex,
              children: [
                HomePage(), // HOME (Index 0: Urgent Attention)
                InventoryPage(), // PRODUCTS (Index 1: Filtered product list)
                AddNewProductScreen(), // ADD
                NotificationPage(), // NOTIFICATION
                ProfilePage(), // PROFILE
              ],
            ),
      ),
      bottomNavigationBar: Consumer<DashboardProvider>(
        builder: (context, dashboardViewModel, child) {
          return BottomNavigationBar(
            selectedItemColor: Theme.of(context).colorScheme.primary,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedItemColor:
                Theme.of(context).brightness == Brightness.light
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,

            backgroundColor: Theme.of(context).colorScheme.surface,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.inventory),
                label: 'Products',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.add_box_rounded),
                label: 'Add',
              ),
              BottomNavigationBarItem(
                icon: Consumer<NotificationViewModel>(
                  builder: (context, notifVm, child) {
                    return Badge(
                      isLabelVisible: notifVm.unreadCount > 0,
                      label: Text(
                        '${notifVm.unreadCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Icon(Icons.notifications),
                    );
                  },
                ),
                label: 'Notification',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            onTap: (value) {
              dashboardViewModel.changeBottomNavIndex(value);
            },
            currentIndex: dashboardViewModel.currentIndex,
          );
        },
      ),
    );
  }
}
