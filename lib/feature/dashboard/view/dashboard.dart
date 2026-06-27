import 'dart:developer';

import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/feature/dashboard/viewmodel/dashboard_provider.dart';
import 'package:easyexpire/feature/home/view/home_page.dart';
import 'package:easyexpire/feature/inventory/view/add_new_product_screen.dart';
import 'package:easyexpire/feature/inventory/view/inventory_page.dart';
import 'package:easyexpire/feature/notification/view/notification_page.dart';
import 'package:easyexpire/feature/profile/view/profile_page.dart';
import 'package:easyexpire/widgets/overview_card.dart';
import 'package:easyexpire/widgets/urgent_attention_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class Dashboard extends StatelessWidget {
  const Dashboard({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DashboardProvider>(builder: (context, provider, child) => IndexedStack(
        index: provider.currentIndex,
        children: [
          HomePage(), //HOME
          InventoryPage(),
          AddNewProductScreen(), //INVENTORY
          NotificationPage(), //NOTIFICATION
          ProfilePage(), //PROFILE
        ],
      ),),
      bottomNavigationBar: Consumer<DashboardProvider>(builder: (context, dashboardViewModel, child) {
        return BottomNavigationBar(
          selectedItemColor: AppColors.primary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedItemColor: AppColors.bottomNavInactiveIcon,
          items:
          [
            BottomNavigationBarItem(icon: Icon(Icons.home),label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory),label: 'Products'),
            BottomNavigationBarItem(icon: Icon(Icons.add_box_rounded),label: 'Add'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications),label: 'Notification'),
            BottomNavigationBarItem(icon: Icon(Icons.person),label: 'Profile'),
          ],onTap: (value) {
          log("XXXXX:$value");
          dashboardViewModel.changeBottomNavIndex(value);
        },
          currentIndex: dashboardViewModel.currentIndex,);
      },),
    );
  }
}




