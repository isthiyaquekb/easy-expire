import 'package:easyexpire/core/utils/ocr_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  group('OcrParseResult Tests', () {
    test('hasAnyResult returns true when date or batch present', () {
      final resWithDate = OcrParseResult(expiryDate: DateTime(2026, 12, 31));
      expect(resWithDate.hasAnyResult, isTrue);

      final resWithBatch = const OcrParseResult(batchNumber: 'LOT-1234');
      expect(resWithBatch.hasAnyResult, isTrue);

      final resEmpty = const OcrParseResult();
      expect(resEmpty.hasAnyResult, isFalse);
    });

    test('matchesFor compares date at month precision and batch string', () {
      final res1 = OcrParseResult(
        expiryDate: DateTime(2026, 12, 1),
        batchNumber: 'B123',
      );
      final res2 = OcrParseResult(
        expiryDate: DateTime(2026, 12, 15), // different day, same month/year
        batchNumber: 'B123',
      );
      final res3 = OcrParseResult(
        expiryDate: DateTime(2026, 11, 1),
        batchNumber: 'B123',
      );

      expect(res1.matchesFor(res2), isTrue);
      expect(res1.matchesFor(res3), isFalse);
    });

    test(
      'hasLowConfidenceResult detects fallback and unlabeled guess sources',
      () {
        final res1 = const OcrParseResult(
          batchNumber: 'A123',
          batchSource: OcrFieldSource.unlabeledGuess,
        );
        expect(res1.hasLowConfidenceResult, isTrue);
        expect(res1.batchIsUnlabeledGuess, isTrue);

        final res2 = const OcrParseResult(
          batchNumber: 'B999',
          batchSource: OcrFieldSource.spatial,
        );
        expect(res2.hasLowConfidenceResult, isFalse);
        expect(res2.batchIsUnlabeledGuess, isFalse);
      },
    );
  });

  group('OcrParser Parsing Pipeline Tests', () {
    test('parses full text fallback when no blocks given', () {
      final recognized = RecognizedText(
        text: 'EXP: 12/2026\nBATCH: AFLV25079',
        blocks: [],
      );

      final result = OcrParser.parse(recognized);
      expect(result.expiryDate, isNotNull);
      expect(result.expiryDate?.year, equals(2026));
      expect(result.expiryDate?.month, equals(12));
      expect(result.batchNumber, equals('AFLV25079'));
    });

    test('parses DD/MM/YYYY date format correctly in fallback', () {
      final recognized = RecognizedText(
        text: 'Best Before: 25/10/2027\nLot No: LT4567',
        blocks: [],
      );

      final result = OcrParser.parse(recognized);
      expect(result.expiryDate, equals(DateTime(2027, 10, 25)));
      expect(result.batchNumber, equals('LT4567'));
    });
  });
}
