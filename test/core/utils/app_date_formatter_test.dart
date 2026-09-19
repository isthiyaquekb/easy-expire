import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyexpire/utils/Formatter/app_date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDateFormatter Tests', () {
    test('formatDDYYMM formats DateTime to dd-MM-yyyy', () {
      final date = DateTime(2026, 9, 19);
      final formatted = AppDateFormatter.formatDDYYMM(date);
      expect(formatted, equals('19-09-2026'));
    });

    test('formatDDMMYYYYHHmm formats ISO date string correctly', () {
      const iso = '2026-09-19T14:30:00.000Z';
      final formatted = AppDateFormatter.formatDDMMYYYYHHmm(iso);
      expect(formatted, contains('19.9.2026'));
      expect(formatted, contains('14:30'));
    });

    test('dateTimeFromFirebase converts Timestamp to dd-MM-yyyy string', () {
      final date = DateTime(2026, 12, 25);
      final timestamp = Timestamp.fromDate(date);
      final formatted = AppDateFormatter.dateTimeFromFirebase(timestamp);
      expect(formatted, equals('25-12-2026'));
    });

    test(
      'firebaseTimestampFormatter parses valid string and handles error gracefully',
      () {
        final validStr = '2026-09-19 14:00:00.000';
        final timestamp = AppDateFormatter.firebaseTimestampFormatter(validStr);
        expect(timestamp.toDate().year, equals(2026));
        expect(timestamp.toDate().month, equals(9));
        expect(timestamp.toDate().day, equals(19));

        final invalidStr = 'not-a-date';
        final fallbackTimestamp = AppDateFormatter.firebaseTimestampFormatter(
          invalidStr,
        );
        expect(fallbackTimestamp, isA<Timestamp>());
      },
    );
  });
}
