import 'package:easyexpire/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:easyexpire/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RingtoneSelectionPage extends StatelessWidget {
  const RingtoneSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CommonAppBar(title: 'Alert Tones', isBack: true),
      body: Consumer<SettingsViewmodel>(
        builder: (context, provider, child) {
          if (provider.ringtoneList.isEmpty) {
            return Center(
              child: Text(
                'No ringtones available',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.ringtoneList.length,
            itemBuilder: (context, index) {
              final tone = provider.ringtoneList[index];
              final isSelected = tone.title == provider.selectedRingtone;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: InkWell(
                  onTap: () {
                    provider.selectRingtone(tone);
                    provider.playSound(tone.path);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? theme.colorScheme.primary.withValues(
                                alpha: isDark ? 0.2 : 0.08,
                              )
                              : theme.colorScheme.surface,
                      border: Border.all(
                        color:
                            isSelected
                                ? theme.colorScheme.primary
                                : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color:
                              isSelected
                                  ? theme.colorScheme.primary
                                  : (isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[400]),
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            tone.title,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            provider.playSound(tone.path);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              color: theme.colorScheme.primary,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
