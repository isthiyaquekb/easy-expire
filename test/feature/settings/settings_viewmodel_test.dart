import 'package:easyexpire/core/constant/app_keys.dart';
import 'package:easyexpire/feature/settings/model/ringtone_model.dart';
import 'package:easyexpire/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import '../../test_helper.dart';

void main() {
  setupTestEnvironment();

  group('SettingsViewmodel Unit Tests', () {
    late SettingsViewmodel viewModel;

    setUp(() async {
      await GetStorage.init();
      viewModel = SettingsViewmodel();
    });

    test('Initial default leadDays is 3', () {
      expect(viewModel.leadDays, 3);
      expect(viewModel.selectedRingtone, 'Default (System)');
      expect(viewModel.isNotificationEnable, false);
      expect(viewModel.isLoading, false);
    });

    test('setLeadDays updates leadDays and notifies listeners', () async {
      int notifyCount = 0;
      viewModel.addListener(() {
        notifyCount++;
      });

      await viewModel.setLeadDays(7);
      expect(viewModel.leadDays, 7);
      expect(notifyCount, greaterThan(0));

      final storage = GetStorage();
      expect(storage.read<int>(AppKeys.keyLeadDays), 7);
    });

    test(
      'selectRingtone updates selected tone and persists to storage',
      () async {
        int notifyCount = 0;
        viewModel.addListener(() {
          notifyCount++;
        });

        final tone = RingtoneModel(title: 'Chime Bell', path: 'chime', id: 2);
        await viewModel.selectRingtone(tone);

        expect(viewModel.selectedRingtone, 'Chime Bell');
        expect(notifyCount, greaterThan(0));

        final storage = GetStorage();
        expect(storage.read<String>(AppKeys.keySelectedRingtone), 'Chime Bell');
      },
    );

    test(
      'loadRingtones populates ringtoneList with fallback presets on test environment',
      () async {
        await viewModel.loadRingtones();
        expect(viewModel.ringtoneList.isNotEmpty, true);
        expect(
          viewModel.ringtoneList.any((r) => r.title == 'Default (System)'),
          true,
        );
        expect(
          viewModel.ringtoneList.any((r) => r.title == 'Urgent Alarm'),
          true,
        );
      },
    );
  });
}
