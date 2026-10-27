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

    testWidgets('triggers onEdit callback when Edit menu item is tapped', (
      WidgetTester tester,
    ) async {
      bool editTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductInventoryCard(
              productName: 'Fresh Butter',
              batchId: 'B-101',
              quantity: 10,
              maxQuantity: 100,
              daysLeft: 5,
              onEdit: () {
                editTapped = true;
              },
            ),
          ),
        ),
      );

      final menuButton = find.byType(PopupMenuButton<String>);
      expect(menuButton, findsOneWidget);

      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      final editItem = find.text('Edit');
      expect(editItem, findsOneWidget);

      await tester.tap(editItem);
      await tester.pumpAndSettle();

      expect(editTapped, isTrue);
    });

    testWidgets('triggers onDelete callback when Delete menu item is tapped', (
      WidgetTester tester,
    ) async {
      bool deleteTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductInventoryCard(
              productName: 'Fresh Butter',
              batchId: 'B-101',
              quantity: 10,
              maxQuantity: 100,
              daysLeft: 5,
              onDelete: () {
                deleteTapped = true;
              },
            ),
          ),
        ),
      );

      final menuButton = find.byType(PopupMenuButton<String>);
      expect(menuButton, findsOneWidget);

      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      final deleteItem = find.text('Delete');
      expect(deleteItem, findsOneWidget);

      await tester.tap(deleteItem);
      await tester.pumpAndSettle();

      expect(deleteTapped, isTrue);
    });
  });
}
