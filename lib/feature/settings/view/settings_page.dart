import 'package:easyexpire/core/constant/app_routes.dart';
import 'package:easyexpire/feature/settings/view/support_feedback_sheet.dart';
import 'package:easyexpire/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:easyexpire/core/services/product_notification_coordinator.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:flutter/foundation.dart';
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
              if (!provider.isNotificationEnable)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Notifications Disabled',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Expiry alerts cannot be delivered while notification permission is denied. Inventory features remain fully accessible.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => provider.openPermissionSettings(),
                        icon: const Icon(Icons.settings_outlined, size: 16),
                        label: const Text('Open Device Settings'),
                      ),
                    ],
                  ),
                ),
              ListTile(
                leading: Icon(Icons.alarm_on_outlined, color: iconColor),
                title: Text(
                  'Urgent Reminders (Expiring Today)',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                subtitle: Text(
                  'Every ${provider.urgentReminderIntervalHours} hours for items expiring today',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showUrgentIntervalDialog(context, provider),
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
              ListTile(
                leading: Icon(Icons.storefront_outlined, color: iconColor),
                title: Text(
                  'Store Opening Time',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                subtitle: Text(
                  'Store opens at ${provider.storeOpeningTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showTimePicker(context, provider),
              ),
              ListTile(
                leading: Icon(Icons.alarm_outlined, color: iconColor),
                title: Text(
                  'Digest Lead Time',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                subtitle: Text(
                  'Deliver ${provider.notifyLeadMinutes} minutes before opening',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _showLeadMinutesDialog(context, provider),
              ),
              ListTile(
                leading: Icon(Icons.schedule_outlined, color: iconColor),
                title: Text(
                  'Digest Schedule',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                subtitle: Text(
                  provider.calculatedDigestTimeDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.public_outlined, color: iconColor),
                title: Text(
                  'Store Timezone',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                subtitle: Text(
                  provider.timezone,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
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

              if (kDebugMode) ...[
                Divider(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  height: 32,
                ),
                _buildSectionHeader(theme, 'DEBUG DIAGNOSTICS'),
                ListTile(
                  leading: Icon(Icons.bug_report_outlined, color: iconColor),
                  title: Text(
                    'Dump Pending Notifications',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    'View pending notifications and log with [NOTIF] tag',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () async {
                    final requests =
                        await ProductNotificationCoordinator.dumpPendingNotifications();
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: Text(
                              'Pending Notifications (${requests.length})',
                            ),
                            content: SizedBox(
                              width: double.maxFinite,
                              child:
                                  requests.isEmpty
                                      ? const Text(
                                        'No pending notifications scheduled.',
                                      )
                                      : ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: requests.length,
                                        itemBuilder:
                                            (ctx, i) => ListTile(
                                              dense: true,
                                              title: Text(
                                                '${requests[i].title} (ID: ${requests[i].id})',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Text(
                                                '${requests[i].body}\nPayload: ${requests[i].payload}',
                                              ),
                                            ),
                                      ),
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Close'),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.alarm_add_outlined, color: iconColor),
                  title: Text(
                    'Schedule test digest in 1 minute',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    'Schedules a local digest notification 60s from now for immediate testing',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  trailing: const Icon(Icons.play_arrow_outlined, size: 20),
                  onTap: () async {
                    await provider.scheduleTestDigestInOneMinute();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '[NOTIF] Test digest scheduled for 1 minute from now. Close app or lock screen to test delivery!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],

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

  void _showTimePicker(BuildContext context, SettingsViewmodel provider) async {
    final parts = provider.storeOpeningTime.split(':');
    final initialHour = int.tryParse(parts.first) ?? 10;
    final initialMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await provider.setStoreOpeningTime(formatted);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Store opening time updated to $formatted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showLeadMinutesDialog(BuildContext context, SettingsViewmodel provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Digest Lead Time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [15, 30, 45, 60, 90, 120].map((mins) {
              return RadioListTile<int>(
                title: Text('$mins minutes before opening'),
                value: mins,
                groupValue: provider.notifyLeadMinutes,
                onChanged: (val) {
                  if (val != null) {
                    provider.setNotifyLeadMinutes(val);
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

  void _showUrgentIntervalDialog(
    BuildContext context,
    SettingsViewmodel provider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Urgent Reminder Interval'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [2, 4].map((hours) {
              return RadioListTile<int>(
                title: Text('Every $hours hours'),
                subtitle: Text(
                  hours == 2
                      ? 'Frequent alerts for items expiring today'
                      : 'Moderate alerts for items expiring today',
                  style: const TextStyle(fontSize: 12),
                ),
                value: hours,
                groupValue: provider.urgentReminderIntervalHours,
                onChanged: (val) {
                  if (val != null) {
                    provider.setUrgentReminderIntervalHours(val);
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
