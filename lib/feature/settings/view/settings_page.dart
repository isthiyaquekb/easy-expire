import 'package:easyexpire/core/constant/app_colors.dart';
import 'package:easyexpire/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsViewmodel>(context, listen: false);
      settingsProvider.initialize();
    });
    return Scaffold(
      backgroundColor: AppColors.scaffoldColor,
      appBar: CommonAppBar(title: 'Settings', isBack: true),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Help',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Report a Bug'),
            onTap: () {
              // Navigate to bug report form or dialog
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Share Feedback'),
            onTap: () {
              // Navigate to feedback form
            },
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Request a Feature'),
            onTap: () {
              // Navigate to feature request form
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Consumer<SettingsViewmodel>(builder: (context, provider, child) =>  SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notifications'),
            value: provider.isNotificationEnable,
            onChanged: (val) {
              // Toggle notification alert sound
              provider.change(val);
            },
          ),),
          // ListTile(
          //   leading: const Icon(Icons.music_note_outlined),
          //   title: const Text('Set Ringtone'),
          //   onTap: () {
          //     // Navigate to ringtone selection
          //     Navigator.pushNamed(context, AppRoutes.ringtoneSelection);
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined),
            title: const Text('Delete My Account'),
            onTap: () {
              // Show confirmation dialog
            },
          ),
        ],
      ),
    );
  }
}
