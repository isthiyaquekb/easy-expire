import 'dart:developer';

import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/feature/home/viewmodel/home_viewmodel.dart';
import 'package:easyexpire/feature/profile/viewmodel/profile_viewmodel.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:easyexpire/widgets/profile_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileViewmodel>(context, listen: false);
      profileProvider.initialize();
    });

    return  Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: CommonAppBar(title: "Profile",isBack: false,),
      body: Consumer<ProfileViewmodel>(
        builder: (context, profileVm, child) {
          final user = profileVm.userModel;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Stack(
                  children: [
                    CircleAvatar(radius: 50, backgroundImage: NetworkImage(user.phone ?? '')),
                    Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 15, backgroundColor: Colors.black, child: Icon(Icons.edit, size: 15, color: Colors.white))),
                  ],
                ),
                const SizedBox(height: 16),
                Text(user.storeName ?? "User", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(user.storeName ?? "Store Manager", style: TextStyle(color: Colors.grey[600])),

                const SizedBox(height: 24),

                // Store Details Container
                _buildSection("STORE DETAILS", [
                  ListTile(leading: const Icon(Icons.store), title: const Text("Store Name"), subtitle: Text(user.storeName ?? "")),
                  ListTile(leading: const Icon(Icons.location_on), title: const Text("Location"), subtitle: Text(user.storeAddress ?? "")),
                  ListTile(leading: const Icon(Icons.email), title: const Text("Contact Email"), subtitle: Text(user.email ?? "")),
                ]),

                // Preferences Container
                _buildSection("PREFERENCES & SETTINGS", [
                  ProfileButton(icon: Icons.person_outline, title: "Edit Profile", onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile)),
                  ProfileButton(icon: Icons.notifications_none, title: "Notification Preferences", onTap: () {}),
                  ProfileButton(icon: Icons.wb_sunny_outlined, title: "App Theme", trailing: "Light", onTap: () {}),
                  ProfileButton(icon: Icons.lock_outline, title: "Security", onTap: () {}),
                  Consumer<HomeViewModel>(builder: (context, homeVm, _) => ProfileButton(
                    icon: Icons.logout, title: "Logout", isLogout: true, onTap: () async {
                    await homeVm.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                  },
                  )),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _buildSection(String title, List<Widget> children) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]))),
        ...children
      ],
    ),
  );
}

class ProfileTextWidget extends StatelessWidget {
  String icons;
  String title;
  String value;
  ProfileTextWidget({
    required this.icons,
    required this.title,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SvgPicture.asset(icons,height: 24,width: 24,colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               /* Text(title,style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textColor),),*/
                Text(value,
                  maxLines: 2,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary),)
              ],
            ),
          )
        ],
      ),
    );
  }
}
