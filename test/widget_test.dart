import 'package:easyexpire/feature/dashboard/viewmodel/dashboard_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardProvider Smoke Test', () {
    test('default index is 0 and updates on changeBottomNavIndex', () {
      final provider = DashboardProvider();
      expect(provider.currentIndex, equals(0));

      provider.changeBottomNavIndex(2);
      expect(provider.currentIndex, equals(2));

      provider.changeBottomNavIndex(3);
      expect(provider.currentIndex, equals(3));
    });
  });
}
