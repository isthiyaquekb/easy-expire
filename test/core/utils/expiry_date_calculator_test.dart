import 'package:easyexpire/core/utils/expiry_date_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateCalendarDaysRemaining Tests', () {
    test('10 days remaining calculation', () {
      final ref = DateTime(2026, 10, 10, 14, 0);
      final expiry = DateTime(2026, 10, 20, 9, 30);
      expect(calculateCalendarDaysRemaining(expiry, ref), equals(10));
    });

    test('2 days remaining calculation', () {
      final ref = DateTime(2026, 5, 1, 10, 0);
      final expiry = DateTime(2026, 5, 3, 18, 0);
      expect(calculateCalendarDaysRemaining(expiry, ref), equals(2));
    });

    test('1 day remaining calculation', () {
      final ref = DateTime(2026, 5, 1, 23, 50);
      final expiry = DateTime(2026, 5, 2, 0, 10);
      expect(calculateCalendarDaysRemaining(expiry, ref), equals(1));
    });

    test('0 days remaining (same calendar date)', () {
      final ref = DateTime(2026, 7, 15, 8, 0);
      final expiry = DateTime(2026, 7, 15, 22, 0);
      expect(calculateCalendarDaysRemaining(expiry, ref), equals(0));
    });

    test('-1 day remaining (expired yesterday)', () {
      final ref = DateTime(2026, 7, 16, 0, 15);
      final expiry = DateTime(2026, 7, 15, 23, 45);
      expect(calculateCalendarDaysRemaining(expiry, ref), equals(-1));
    });

    test('Expiry date at midnight with reference time late at night', () {
      final ref = DateTime(2026, 8, 10, 23, 59, 59);
      final expiry = DateTime(2026, 8, 11, 0, 0, 0);
      // Even though only 1 second elapsed, it is the next calendar day
      expect(calculateCalendarDaysRemaining(expiry, ref), equals(1));
    });

    test('Dates differing by hours on the same calendar day return 0', () {
      final morning = DateTime(2026, 4, 10, 0, 1);
      final night = DateTime(2026, 4, 10, 23, 59);
      expect(calculateCalendarDaysRemaining(night, morning), equals(0));
      expect(calculateCalendarDaysRemaining(morning, night), equals(0));
    });

    test('Month boundary transition (October 31 to November 1)', () {
      final ref = DateTime(2026, 10, 31, 22, 0);
      final expiry = DateTime(2026, 11, 1, 8, 0);
      expect(calculateCalendarDaysRemaining(expiry, ref), equals(1));
    });

    test(
      'Month boundary spanning multiple days (Feb 28 to Mar 2 in non-leap year)',
      () {
        final ref = DateTime(2027, 2, 28, 12, 0);
        final expiry = DateTime(2027, 3, 2, 12, 0);
        expect(calculateCalendarDaysRemaining(expiry, ref), equals(2));
      },
    );

    test('Year boundary transition (December 31 to January 1)', () {
      final ref = DateTime(2026, 12, 31, 23, 0);
      final expiry = DateTime(2027, 1, 1, 9, 0);
      expect(calculateCalendarDaysRemaining(expiry, ref), equals(1));
    });

    test('Leap year: Feb 28 to Feb 29 (2028 is a leap year)', () {
      final ref = DateTime(2028, 2, 28, 10, 0);
      final expiry = DateTime(2028, 2, 29, 10, 0);
      expect(calculateCalendarDaysRemaining(expiry, ref), equals(1));
    });

    test('Leap year: Feb 28 to Mar 1 in 2028 returns 2 days', () {
      final ref = DateTime(2028, 2, 28, 10, 0);
      final expiry = DateTime(2028, 3, 1, 10, 0);
      expect(calculateCalendarDaysRemaining(expiry, ref), equals(2));
    });

    test('Non-leap year: Feb 28 to Mar 1 in 2027 returns 1 day', () {
      final ref = DateTime(2027, 2, 28, 10, 0);
      final expiry = DateTime(2027, 3, 1, 10, 0);
      expect(calculateCalendarDaysRemaining(expiry, ref), equals(1));
    });
  });

  group('generateStableNotificationId Tests', () {
    test('produces identical ID for identical string across calls', () {
      const docId = 'product_doc_xyz_789';
      final id1 = generateStableNotificationId(docId);
      final id2 = generateStableNotificationId(docId);
      expect(id1, equals(id2));
    });

    test('produces different IDs for distinct keys', () {
      final id1 = generateStableNotificationId('product_1');
      final id2 = generateStableNotificationId('product_2');
      expect(id1, isNot(equals(id2)));
    });

    test('returns non-negative 31-bit integer within valid range', () {
      final keys = [
        'a',
        'b',
        '12345',
        'product_long_identifier_abc_123',
        '!@#\$%',
      ];
      for (final key in keys) {
        final id = generateStableNotificationId(key);
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });
  });

  group('evaluateNotificationSchedule Decision Tests', () {
    final ref = DateTime(2026, 10, 18, 10, 0);

    test('Within warning window (4 days) triggers daily reminder with expected body', () {
      final expiry = ref.add(const Duration(days: 4));
      final decision = evaluateNotificationSchedule(
        productName: 'Milk',
        expiryDate: expiry,
        referenceTime: ref,
      );

      expect(decision.shouldNotify, isTrue);
      expect(decision.tier, equals(ExpiryNotificationTier.dailyReminder));
      expect(decision.daysRemaining, equals(4));
      expect(decision.body, equals('Milk will expire in 4 days!'));
    });

    test('Beyond warning window (10 days) is safe and does not notify', () {
      final expiry = ref.add(const Duration(days: 10));
      final decision = evaluateNotificationSchedule(
        productName: 'Milk',
        expiryDate: expiry,
        referenceTime: ref,
      );

      expect(decision.shouldNotify, isFalse);
      expect(decision.tier, equals(ExpiryNotificationTier.safe));
      expect(decision.daysRemaining, equals(10));
    });

    test('1 day remaining triggers tomorrow reminder text', () {
      final expiry = ref.add(const Duration(days: 1));
      final decision = evaluateNotificationSchedule(
        productName: 'Yogurt',
        expiryDate: expiry,
        referenceTime: ref,
      );

      expect(decision.shouldNotify, isTrue);
      expect(decision.tier, equals(ExpiryNotificationTier.dailyReminder));
      expect(decision.body, equals('Yogurt will expire tomorrow!'));
    });

    test(
      'Daily reminder deduplication: throttles if already notified today',
      () {
        final expiry = ref.add(const Duration(days: 3));
        // Notified 2 hours ago on the SAME calendar date
        final lastNotified = ref.subtract(const Duration(hours: 2));

        final decision = evaluateNotificationSchedule(
          productName: 'Cheese',
          expiryDate: expiry,
          referenceTime: ref,
          lastNotifiedAt: lastNotified,
        );

        expect(decision.shouldNotify, isFalse);
        expect(decision.reason, contains('Already notified today'));
      },
    );

    test('Daily reminder allows notification if last notified yesterday', () {
      final expiry = ref.add(const Duration(days: 3));
      // Notified yesterday
      final lastNotified = ref.subtract(const Duration(days: 1));

      final decision = evaluateNotificationSchedule(
        productName: 'Cheese',
        expiryDate: expiry,
        referenceTime: ref,
        lastNotifiedAt: lastNotified,
      );

      expect(decision.shouldNotify, isTrue);
    });

    test(
      'Zero days remaining triggers zero-day alert when no prior notification',
      () {
        final expiry = ref; // same day
        final decision = evaluateNotificationSchedule(
          productName: 'Sandwich',
          expiryDate: expiry,
          referenceTime: ref,
        );

        expect(decision.shouldNotify, isTrue);
        expect(decision.tier, equals(ExpiryNotificationTier.zeroDayReminder));
        expect(decision.title, equals('Product Expires TODAY'));
        expect(decision.body, equals('Sandwich is expiring today!'));
      },
    );

    test(
      'Zero days remaining throttles within 120 minutes of last notification',
      () {
        final expiry = ref;
        // Notified 60 minutes ago
        final lastNotified = ref.subtract(const Duration(minutes: 60));

        final decision = evaluateNotificationSchedule(
          productName: 'Sandwich',
          expiryDate: expiry,
          referenceTime: ref,
          lastNotifiedAt: lastNotified,
        );

        expect(decision.shouldNotify, isFalse);
        expect(decision.reason, contains('Throttled'));
      },
    );

    test(
      'Zero days remaining permits notification after 120 minutes elapsed',
      () {
        final expiry = ref;
        // Notified 121 minutes ago
        final lastNotified = ref.subtract(const Duration(minutes: 121));

        final decision = evaluateNotificationSchedule(
          productName: 'Sandwich',
          expiryDate: expiry,
          referenceTime: ref,
          lastNotifiedAt: lastNotified,
        );

        expect(decision.shouldNotify, isTrue);
      },
    );

    test(
      'Expired item (negative days) stops notification and marks for cancel',
      () {
        final expiry = ref.subtract(const Duration(days: 2));
        final decision = evaluateNotificationSchedule(
          productName: 'Old Bread',
          expiryDate: expiry,
          referenceTime: ref,
        );

        expect(decision.shouldNotify, isFalse);
        expect(decision.tier, equals(ExpiryNotificationTier.expired));
        expect(decision.reason, contains('already expired'));
      },
    );
  });
}
