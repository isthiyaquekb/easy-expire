import 'package:easyexpire/widgets/overview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverviewCard Widget Tests', () {
    testWidgets('renders title, count, subtitle, and badge text correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewCard(
              title: 'Expired',
              count: '12',
              subtitle: 'SKUs to pull immediately',
              badgeText: 'Action Required',
              badgeBgColor: Colors.red.shade100,
              badgeTextColor: Colors.red.shade900,
              borderColor: Colors.red.shade300,
            ),
          ),
        ),
      );

      expect(find.text('EXPIRED'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('SKUs to pull immediately'), findsOneWidget);
      expect(find.text('ACTION REQUIRED'), findsOneWidget);
    });
  });
}
