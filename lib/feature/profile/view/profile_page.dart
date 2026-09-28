import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/feature/home/viewmodel/home_viewmodel.dart';
import 'package:easyexpire/feature/profile/viewmodel/profile_viewmodel.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:easyexpire/widgets/profile_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:easyexpire/core/theme/theme_view_model.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileViewmodel>(
        context,
        listen: false,
      );
      profileProvider.initialize();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CommonAppBar(title: "Profile", isBack: false),
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
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(
                          Icons.edit,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user.storeName.isNotEmpty ? user.storeName : "Store Manager",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email.isNotEmpty ? user.email : "Store Manager",
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 24),

                // Store Details Container
                _buildSection(context, "STORE DETAILS", [
                  ListTile(
                    leading: Icon(
                      Icons.store,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      "Store Name",
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                    ),
                    subtitle: Text(
                      user.storeName.isNotEmpty ? user.storeName : "Not set",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      "Location",
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                    ),
                    subtitle: Text(
                      user.storeAddress.isNotEmpty
                          ? user.storeAddress
                          : "Not set",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.email,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      "Contact Email",
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                    ),
                    subtitle: Text(
                      user.email.isNotEmpty ? user.email : "Not set",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ]),

                // Preferences Container
                _buildSection(context, "PREFERENCES & SETTINGS", [
                  ProfileButton(
                    icon: Icons.person_outline,
                    title: "Edit Profile",
                    onTap:
                        () =>
                            Navigator.pushNamed(context, AppRoutes.editProfile),
                  ),
                  ProfileButton(
                    icon: Icons.notifications_none,
                    title: "Notification Preferences",
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.settings);
                    },
                  ),
                  Consumer<ThemeViewModel>(
                    builder: (context, themeVm, _) {
                      final isDarkTheme =
                          Theme.of(context).brightness == Brightness.dark;
                      return ProfileButton(
                        icon:
                            isDarkTheme
                                ? Icons.dark_mode_outlined
                                : Icons.wb_sunny_outlined,
                        title: "App Theme",
                        trailing: isDarkTheme ? "Dark" : "Light",
                        onTap: () {
                          themeVm.toggleTheme();
                        },
                      );
                    },
                  ),
                  ProfileButton(
                    icon: Icons.lock_outline,
                    title: "Security",
                    onTap: () {},
                  ),
                  Consumer<HomeViewModel>(
                    builder:
                        (context, homeVm, _) => ProfileButton(
                          icon: Icons.logout,
                          title: "Logout",
                          isLogout: true,
                          onTap: () async {
                            await homeVm.signOut();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.login,
                              (route) => false,
                            );
                          },
                        ),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _buildSection(
  BuildContext context,
  String title,
  List<Widget> children,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey[600],
            ),
          ),
        ),
        ...children,
      ],
    ),
  );
}

class ProfileTextWidget extends StatelessWidget {
  final String icons;
  final String title;
  final String value;
  const ProfileTextWidget({
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
            child: SvgPicture.asset(
              icons,
              height: 24,
              width: 24,
              colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
