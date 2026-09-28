import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/feature/settings/view/support_feedback_sheet.dart';
import 'package:easyexpire/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsViewmodel>(
        context,
        listen: false,
      );
      settingsProvider.initialize();
    });
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CommonAppBar(title: 'Settings', isBack: true),
      body: Consumer<SettingsViewmodel>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: [
              // ── 1. HELP & SUPPORT ───────────────────────────────────────
              _buildSectionHeader(theme, 'HELP & SUPPORT'),
              ListTile(
                leading: Icon(Icons.bug_report_outlined, color: iconColor),
                title: Text(
                  'Report a Bug',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  SupportFeedbackSheet.show(context, type: FeedbackType.bug);
                },
              ),
              ListTile(
                leading: Icon(Icons.star_outline, color: iconColor),
                title: Text(
                  'Share Feedback',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  SupportFeedbackSheet.show(
                    context,
                    type: FeedbackType.feedback,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.lightbulb_outline, color: iconColor),
                title: Text(
                  'Request a Feature',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  SupportFeedbackSheet.show(
                    context,
                    type: FeedbackType.feature,
                  );
                },
              ),

              Divider(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                height: 32,
              ),

              // ── 2. NOTIFICATIONS & ALERTS ──────────────────────────────
              _buildSectionHeader(theme, 'NOTIFICATIONS & ALERTS'),
              SwitchListTile(
                secondary: Icon(
                  Icons.notifications_active_outlined,
                  color: iconColor,
                ),
                title: Text(
                  'Push Notifications',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                subtitle: Text(
                  'Receive automatic alerts for expiring inventory',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                activeColor: theme.colorScheme.primary,
                value: provider.isNotificationEnable,
                onChanged: (val) {
                  provider.change(val);
                },
              ),
              ListTile(
                leading: Icon(Icons.music_note_outlined, color: iconColor),
                title: Text(
                  'Alert Tone',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                subtitle: Text(
                  provider.selectedRingtone,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.ringtoneSelection);
                },
              ),
              ListTile(
                leading: Icon(Icons.timer_outlined, color: iconColor),
                title: Text(
                  'Alert Timing (Lead Days)',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                subtitle: Text(
                  'Notify ${provider.leadDays} days before expiry',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showLeadDaysDialog(context, provider),
              ),

              Divider(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                height: 32,
              ),

              // ── 3. LEGAL & ABOUT ───────────────────────────────────────
              _buildSectionHeader(theme, 'LEGAL & ABOUT'),
              ListTile(
                leading: Icon(Icons.privacy_tip_outlined, color: iconColor),
                title: Text(
                  'Privacy Policy',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap:
                    () => _showLegalDialog(
                      context,
                      'Privacy Policy',
                      _privacyPolicyText,
                    ),
              ),
              ListTile(
                leading: Icon(Icons.description_outlined, color: iconColor),
                title: Text(
                  'Terms of Service',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap:
                    () => _showLegalDialog(
                      context,
                      'Terms of Service',
                      _termsOfServiceText,
                    ),
              ),

              Divider(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                height: 32,
              ),

              // ── 4. ACCOUNT ─────────────────────────────────────────────
              _buildSectionHeader(theme, 'ACCOUNT'),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete My Account',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Permanently remove all data and store records',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                onTap: () {
                  provider.deleteAccount(context);
                },
              ),

              const SizedBox(height: 24),

              // App Version Footer
              Center(
                child: Text(
                  'Easy Expire v1.0.0 (Build 1)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  void _showLeadDaysDialog(BuildContext context, SettingsViewmodel provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Expiry Alert Lead Days'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                [1, 3, 5, 7, 14].map((days) {
                  return RadioListTile<int>(
                    title: Text('$days days before expiry'),
                    value: days,
                    groupValue: provider.leadDays,
                    onChanged: (val) {
                      if (val != null) {
                        provider.setLeadDays(val);
                        Navigator.of(context).pop();
                      }
                    },
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Text(
                content,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  static const String _privacyPolicyText =
      "Easy Expire respects your privacy. We collect store inventory information, expiry timestamps, and notification tokens solely to provide automated expiration alerts and inventory precision. We do not sell your personal or inventory data to third parties.";

  static const String _termsOfServiceText =
      "By using Easy Expire, you agree to track product inventories accurately. Easy Expire provides expiration notifications as an assistive management tool and assumes no liability for unsold or spoiled inventory.";
}
