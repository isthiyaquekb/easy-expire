import 'package:easyexpire/widgets/urgent_attention_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrgentAttentionTile Widget Tests', () {
    testWidgets(
      'renders product name, quantity and Expired status when daysLeft < 0',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UrgentAttentionTile(
                productName: 'Expired Cheese',
                subtitle: 'Batch: CH-990',
                daysLeft: -1,
                quantity: 5,
                itemLength: 1,
                index: 0,
              ),
            ),
          ),
        );

        expect(find.text('Expired Cheese'), findsOneWidget);
        expect(find.text('Batch: CH-990'), findsOneWidget);
        expect(find.text('Expired'), findsOneWidget);
        expect(find.text('Qty: 5'), findsOneWidget);
      },
    );

    testWidgets('renders Exp. Today when daysLeft == 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UrgentAttentionTile(
              productName: 'Fresh Sushi',
              subtitle: 'Batch: SU-101',
              daysLeft: 0,
              quantity: 8,
              itemLength: 1,
              index: 0,
            ),
          ),
        ),
      );

      expect(find.text('Fresh Sushi'), findsOneWidget);
      expect(find.text('Exp. Today'), findsOneWidget);
    });
  });
}
