import 'package:easyexpire/widgets/product_inventory_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductInventoryCard Widget Tests', () {
    testWidgets('renders product details with correct badge text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductInventoryCard(
              productName: 'Organic Greek Yogurt',
              batchId: 'B-88331',
              quantity: 15,
              maxQuantity: 100,
              daysLeft: 2,
            ),
          ),
        ),
      );

      expect(find.text('Organic Greek Yogurt'), findsOneWidget);
      expect(find.text('Batch ID: B-88331'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('2 DAYS'), findsOneWidget);
    });

    testWidgets('renders expired badge when daysLeft < 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductInventoryCard(
              productName: 'Expired Milk',
              batchId: 'B-0001',
              quantity: 4,
              maxQuantity: 50,
              daysLeft: -1,
            ),
          ),
        ),
      );

      expect(find.text('Expired Milk'), findsOneWidget);
      expect(find.text('EXPIRED'), findsOneWidget);
    });
  });
}
