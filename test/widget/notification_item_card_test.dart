import 'package:easyexpire/widgets/notification_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationItemCard Widget Tests', () {
    testWidgets('renders title, body, and action buttons for expiry alert', (
      WidgetTester tester,
    ) async {
      bool reviewTapped = false;
      bool dismissTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationItemCard(
              notificationId: 'notif_100',
              title: 'Product Expiry Alert',
              body: 'Milk 1L will expire in 2 days!',
              timestamp: DateTime(2026, 9, 19, 14, 30),
              onReviewBatch: () => reviewTapped = true,
              onDismiss: () => dismissTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Product Expiry Alert'), findsOneWidget);
      expect(find.text('Milk 1L will expire in 2 days!'), findsOneWidget);
      expect(find.text('Review Batch'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);

      await tester.tap(find.text('Review Batch'));
      expect(reviewTapped, isTrue);

      await tester.tap(find.text('Dismiss'));
      expect(dismissTapped, isTrue);
    });
  });
}
