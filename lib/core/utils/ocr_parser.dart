// Parses OCR output (RecognizedText) from product packaging and extracts
// expiry date and batch number.
//
// DESIGN — Two-phase spatial strategy:
//   Phase 1 (spatial): Walk every TextLine in the RecognizedText block/line
//     structure. When a line's text matches a label pattern, search the full
//     set of lines for the nearest spatially-adjacent candidate — either on
//     the same row (similar Y-center) or directly below (next-row Y range).
//     Use the first candidate that yields a parseable value.
//   Phase 2 (fallback): If spatial search finds nothing, run regex directly
//     on the flattened .text string. This handles compact single-line labels
//     like "EXP: 12/2027" where label and value are in the same TextLine.
//
// COORDINATE SYSTEM: boundingBox values are in image-sensor pixel space
//   (not screen pixels). Comparisons are purely relative (ratios) so they
//   are resolution-independent.
//
// This file has NO Flutter / platform imports so it works in plain dart test.

import 'dart:developer';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// ── Confidence / source ─────────────────────────────────────────────────────

/// How a field was found during parsing.
enum OcrFieldSource {
  /// Label + value were adjacent in the OCR block/line structure.
  spatial,

  /// Regex matched the flattened text string (lower confidence).
  fullTextFallback,
}

// ── Result type ──────────────────────────────────────────────────────────────

class OcrParseResult {
  /// Detected expiry date, or `null` if not found.
  final DateTime? expiryDate;

  /// How [expiryDate] was detected. `null` when [expiryDate] is `null`.
  final OcrFieldSource? expirySource;

  /// Detected batch number (raw string), or `null` if not found.
  final String? batchNumber;

  /// How [batchNumber] was detected. `null` when [batchNumber] is `null`.
  final OcrFieldSource? batchSource;

  const OcrParseResult({
    this.expiryDate,
    this.expirySource,
    this.batchNumber,
    this.batchSource,
  });

  bool get hasAnyResult => expiryDate != null || batchNumber != null;

  /// Whether any field was found only through the fallback (lower confidence).
  bool get hasLowConfidenceResult =>
      expirySource == OcrFieldSource.fullTextFallback ||
          batchSource == OcrFieldSource.fullTextFallback;

  /// Two results are considered "equal" for the stability-check comparison.
  /// Compare date at month precision (MM/YYYY formats give day=1) and
  /// exact batch string.
  bool matchesFor(OcrParseResult other) {
    final dateMatch = expiryDate == null && other.expiryDate == null ||
        (expiryDate != null &&
            other.expiryDate != null &&
            expiryDate!.year == other.expiryDate!.year &&
            expiryDate!.month == other.expiryDate!.month);

    final batchMatch = batchNumber == other.batchNumber;

    return dateMatch && batchMatch;
  }

  @override
  String toString() => 'OcrParseResult('
      'expiry: $expiryDate [${expirySource?.name}], '
      'batch: $batchNumber [${batchSource?.name}])';
}

// ── Tunable spatial tolerances ───────────────────────────────────────────────
//
// These are the values you can adjust based on real-device testing:
//
// [kSameRowYTolerance]
//   Fraction of the label line's height used as the Y-center comparison
//   window. Two lines are considered "same row" when:
//     |labelCenterY - candidateCenterY| < labelHeight * kSameRowYTolerance
//   Default 0.6 works well for normal-sized text; increase toward 1.0 if
//   labels and values appear at slightly different vertical positions (e.g.
//   superscript/subscript layout).
//
// [kBelowYTolerance]
//   Fraction of the label line's height for the acceptable vertical gap
//   between a label's bottom edge and a candidate's top edge.
//   A candidate is "directly below" when:
//     candidateTop - labelBottom < labelHeight * kBelowYTolerance
//   Default 1.5 allows for up to 1.5× the label height of gap (handles
//   lines with large leading). Increase if your labels are far apart.
//
// [kBelowXTolerance]
//   Fraction of the label's width for horizontal alignment when matching
//   "below" candidates. The candidate's left edge must be within
//   labelWidth * kBelowXTolerance of the label's left edge.
//   Default 1.2 is permissive (value may be inset under a longer label).
//   Decrease to 0.3 if you want strict column alignment.
const double kSameRowYTolerance = 0.6;
const double kBelowYTolerance = 1.5;
const double kBelowXTolerance = 1.2;

// ── Main parser ──────────────────────────────────────────────────────────────

abstract class OcrParser {
  OcrParser._();

  // ── Label regexes ───────────────────────────────────────────────────────

  /// Matches expiry label lines (case-insensitive).
  /// Covers: EXP, EXP., EXPIRY, EXPIRY DATE, USE BY, BEST BEFORE, USE BY DATE
  static final _expiryLabelRe = RegExp(
    r'(?:BEST\s+BEFORE|USE\s+BY(?:\s+DATE)?|EXPIRY(?:\s+DATE)?|EXP(?:IRY)?\.?)',
    caseSensitive: false,
  );

  /// Matches batch label lines.
  /// Covers: BATCH, BATCH#, LOT, LOT#, B.NO, B.NO., BN
  static final _batchLabelRe = RegExp(
    r'(?:BATCH\s*(?:NO\.?|NUMBER|#)?|LOT\s*(?:NO\.?|#)?|B\.?\s*NO\.?|BN)\b',
    caseSensitive: false,
  );

  // ── Date patterns ────────────────────────────────────────────────────────

  /// DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
  static final _ddmmyyyy = RegExp(
    r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})\b',
  );

  /// YYYY-MM-DD (ISO 8601)
  static final _yyyymmdd = RegExp(
    r'\b(\d{4})-(\d{2})-(\d{2})\b',
  );

  /// DD/MM/YY, DD-MM-YY, DD.MM.YY (2-digit year)
  static final _ddmmyy = RegExp(
    r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2})\b',
  );

  /// DD/MMYY "compact" — OCR frequently drops the middle separator in a
  /// DD/MM/YY date, e.g. "12/07/26" gets read as "12/0726". This pattern
  /// catches that: a 1-2 digit day, one separator, then 4 digits that are
  /// really MM+YY glued together. Tried before the generic 4-digit fallback
  /// so a leading day isn't discarded.
  static final _dMmyyCompact = RegExp(
    r'\b(\d{1,2})[\/\-\.](\d{4})\b',
  );

  /// "MAR 2027", "MARCH 2027", "MAR2027", "Mar. 2027"
  static final _monthNameYear = RegExp(
    r'\b(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z]*\.?\s*(\d{4})\b',
    caseSensitive: false,
  );

  /// MM/YYYY or MM-YYYY (no explicit day)
  /// Negative lookahead prevents matching a partial DD/MM/YYYY.
  static final _mmyyyy = RegExp(
    r'\b(\d{2})[\/\-](\d{4})\b(?![\/\-. ]?\d{1,4})',
  );

  /// MM/YY or MM-YY (no explicit day)
  /// Negative lookahead prevents matching a partial DD/MM/YY.
  static final _mmyyWithSlash = RegExp(
    r'\b(\d{2})[\/\-](\d{2})\b(?![\/\-. ]?\d{1,4})',
  );

  /// DDMMYY (6 consecutive digits, no separators)
  static final _sixDigits = RegExp(
    r'\b(\d{6})\b',
  );

  /// MMYY (4 consecutive digits, no separators)
  static final _fourDigits = RegExp(
    r'\b(\d{4})\b',
  );

  // ── Batch value pattern ──────────────────────────────────────────────────

  /// Alphanumeric batch token, at least 2 chars, up to 20.
  static final _batchToken = RegExp(
    r'\b([A-Z0-9][A-Z0-9\-\/\.]{1,19})\b',
    caseSensitive: false,
  );

  // ── Month map ────────────────────────────────────────────────────────────
  static const _monthMap = {
    'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
    'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
  };

  // ── Public entry point ───────────────────────────────────────────────────

  /// Parse [recognizedText] from ML Kit and return a typed [OcrParseResult].
  ///
  /// Delegates to [_spatialParse] first, then [_fallbackParse].
  static OcrParseResult parse(RecognizedText recognizedText) {
    // Flatten all TextLines across all blocks into one searchable list.
    final allLines = <TextLine>[];
    for (final block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }

    return _spatialParse(allLines, recognizedText.text);
  }

  // ── Phase 1: spatial parse ────────────────────────────────────────────────

  static OcrParseResult _spatialParse(
      List<TextLine> allLines,
      String fullText,
      ) {
    DateTime? expiryDate;
    OcrFieldSource? expirySource;
    String? batchNumber;
    OcrFieldSource? batchSource;

    for (final labelLine in allLines) {
      final labelText = labelLine.text;
      final labelBox = labelLine.boundingBox;
      if (labelBox == null) continue;

      // ── Expiry ──────────────────────────────────────────────────────────
      if (expiryDate == null && _expiryLabelRe.hasMatch(labelText)) {
        // Case A: value embedded on the same TextLine after stripping the label.
        final stripped = labelText.replaceAll(_expiryLabelRe, '').trim();
        log("OcrParser: Spatial Expiry Case A - Stripped raw candidate string: '$stripped'");
        final inlineDate = _parseDate(stripped);
        if (inlineDate != null) {
          expiryDate = inlineDate;
          expirySource = OcrFieldSource.spatial;
          log("OcrParser: Spatial Expiry Case A - Succeeded. Date: $expiryDate");
        } else {
          log("OcrParser: Spatial Expiry Case A - Validation failed for '$stripped'. Trying Case B...");
          // Case B: find nearest spatially-adjacent line containing a date.
          final candidate = _findAdjacentValueLine(
            labelBox,
            allLines,
            exclude: labelLine,
            valueCheck: (text) {
              log("OcrParser: Spatial Expiry Case B - Checking RAW candidate string: '$text'");
              final d = _parseDate(text);
              log("OcrParser: Spatial Expiry Case B - Validation result for '$text': $d");
              return d != null;
            },
          );
          if (candidate != null) {
            expiryDate = _parseDate(candidate);
            expirySource = OcrFieldSource.spatial;
            log("OcrParser: Spatial Expiry Case B - Succeeded. Candidate: '$candidate', Date: $expiryDate");
          } else {
            log("OcrParser: Spatial Expiry Case B - Failed. No spatially-adjacent line passed validation.");
          }
        }
      }

      // ── Batch ───────────────────────────────────────────────────────────
      if (batchNumber == null && _batchLabelRe.hasMatch(labelText)) {
        // Case A: value on same line after stripping label.
        final stripped = labelText
            .replaceAll(_batchLabelRe, '')
            .replaceAll(RegExp(r'^[\s:\-]+'), '')
            .trim();
        log("OcrParser: Spatial Batch Case A - Stripped raw candidate string: '$stripped'");
        final inlineBatch = _batchToken.firstMatch(stripped)?.group(1);
        if (inlineBatch != null && inlineBatch.isNotEmpty) {
          batchNumber = inlineBatch;
          batchSource = OcrFieldSource.spatial;
          log("OcrParser: Spatial Batch Case A - Succeeded. Batch: $batchNumber");
        } else {
          log("OcrParser: Spatial Batch Case A - Validation failed for '$stripped'. Trying Case B...");
          // Case B: find nearest spatially-adjacent line that looks like a
          // batch token (alphanumeric, not another label, not a date).
          final candidate = _findAdjacentValueLine(
            labelBox,
            allLines,
            exclude: labelLine,
            valueCheck: (text) {
              final clean = text.trim();
              log("OcrParser: Spatial Batch Case B - Checking RAW candidate string: '$clean'");
              if (_expiryLabelRe.hasMatch(clean)) {
                log("OcrParser: Spatial Batch Case B - Candidate '$clean' rejected because it matches expiry label.");
                return false;
              }
              if (_batchLabelRe.hasMatch(clean)) {
                log("OcrParser: Spatial Batch Case B - Candidate '$clean' rejected because it matches batch label.");
                return false;
              }
              final isMatch = _batchToken.hasMatch(clean);
              log("OcrParser: Spatial Batch Case B - Candidate '$clean' _batchToken match result: $isMatch");
              return isMatch;
            },
          );
          if (candidate != null) {
            batchNumber = _batchToken.firstMatch(candidate)?.group(1);
            batchSource = OcrFieldSource.spatial;
            log("OcrParser: Spatial Batch Case B - Succeeded. Candidate: '$candidate', Batch: $batchNumber");
          } else {
            log("OcrParser: Spatial Batch Case B - Failed. No spatially-adjacent line passed validation.");
          }
        }
      }

      if (expiryDate != null && batchNumber != null) break;
    }

    // ── Phase 2: full-text fallback ────────────────────────────────────────
    final fallback = _fallbackParse(fullText);

    expiryDate ??= fallback.expiryDate;
    expirySource ??=
    fallback.expiryDate != null ? OcrFieldSource.fullTextFallback : null;

    batchNumber ??= fallback.batchNumber;
    batchSource ??=
    fallback.batchNumber != null ? OcrFieldSource.fullTextFallback : null;

    return OcrParseResult(
      expiryDate: expiryDate,
      expirySource: expirySource,
      batchNumber: batchNumber,
      batchSource: batchSource,
    );
  }

  // ── Spatial adjacency search ─────────────────────────────────────────────

  /// Searches [allLines] for the best value candidate adjacent to [labelBox].
  ///
  /// Search order (priority):
  ///   1. Same-row lines to the RIGHT of the label (label is on left,
  ///      value continues on the same row).
  ///   2. Line DIRECTLY BELOW the label (next row, horizontally aligned).
  ///   3. Same-row lines to the LEFT (rare, but some layouts reverse order).
  ///
  /// Returns the text of the best candidate, or `null` if nothing found.
  static String? _findAdjacentValueLine(
      Rect labelBox,
      List<TextLine> allLines, {
        required TextLine exclude,
        required bool Function(String) valueCheck,
      }) {
    // Pre-compute label geometry.
    final labelCenterY = labelBox.center.dy;
    final labelHeight = labelBox.height.clamp(1.0, double.infinity);
    final labelWidth = labelBox.width.clamp(1.0, double.infinity);

    // Collect candidates for each priority bucket.
    _SpatialCandidate? bestSameRowRight;
    _SpatialCandidate? bestBelow;
    _SpatialCandidate? bestSameRowLeft;

    for (final line in allLines) {
      if (identical(line, exclude)) continue;
      final box = line.boundingBox;
      if (box == null) continue;
      final text = line.text.trim();
      if (text.isEmpty || !valueCheck(text)) continue;

      final candidateCenterY = box.center.dy;
      final dY = (candidateCenterY - labelCenterY).abs();

      // ── Same-row check ────────────────────────────────────────────────
      // Two lines are on the same row when their Y-centers are within
      // kSameRowYTolerance × label height of each other.
      if (dY < labelHeight * kSameRowYTolerance) {
        final dX = box.left - labelBox.right; // positive = to the right
        if (dX >= 0) {
          // Right of label — prefer closest.
          if (bestSameRowRight == null || dX < bestSameRowRight.distance) {
            bestSameRowRight = _SpatialCandidate(text, dX);
          }
        } else {
          // Left of label — less preferred.
          final leftDist = (labelBox.left - box.right).abs();
          if (bestSameRowLeft == null || leftDist < bestSameRowLeft.distance) {
            bestSameRowLeft = _SpatialCandidate(text, leftDist);
          }
        }
        continue;
      }

      // ── Below check ───────────────────────────────────────────────────
      // The candidate is "below" when:
      //   1. Its top edge is at or below the label's bottom edge.
      //   2. The gap (candidateTop - labelBottom) < label height × kBelowYTolerance.
      //   3. Its left edge is horizontally close to the label's left edge
      //      (within label width × kBelowXTolerance).
      final gapBelow = box.top - labelBox.bottom;
      final xDiff = (box.left - labelBox.left).abs();
      if (gapBelow >= 0 &&
          gapBelow < labelHeight * kBelowYTolerance &&
          xDiff < labelWidth * kBelowXTolerance) {
        if (bestBelow == null || gapBelow < bestBelow.distance) {
          bestBelow = _SpatialCandidate(text, gapBelow);
        }
      }
    }

    // Return in priority order.
    return bestSameRowRight?.text ?? bestBelow?.text ?? bestSameRowLeft?.text;
  }

  // ── Phase 2: full-text fallback ──────────────────────────────────────────

  /// Scans the flattened [fullText] string. This is the old line-by-line
  /// approach, now used only as a safety net.
  static OcrParseResult _fallbackParse(String fullText) {
    final lines = fullText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    DateTime? expiryDate;
    String? batchNumber;

    // When scanning full text, try to extract specific date-like tokens first
    // before passing the entire noisy string to _parseDate.
    final dateCandidates = <String>[];
    // Add all full lines as candidates.
    dateCandidates.addAll(lines);
    // Also try to find standalone 6-digit or 4-digit numbers from full text.
    final allDigitsRegex = RegExp(r'\b(\d{4}|\d{6})\b'); // 4 or 6 digit numbers
    for (final match in allDigitsRegex.allMatches(fullText)) {
      dateCandidates.add(match.group(0)!);
    }

    // Try parsing each candidate.
    for (final candidate in dateCandidates) {
      expiryDate = _parseDate(candidate);
      if (expiryDate != null) {
        log("OcrParser: Fallback Expiry - Succeeded with candidate: '$candidate'. Date: $expiryDate");
        break;
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Re-check expiry with label if not found yet (just in case).
      if (expiryDate == null && _expiryLabelRe.hasMatch(line)) {
        final valuePart = line.replaceAll(_expiryLabelRe, '').trim();
        log("OcrParser: Fallback Expiry (labeled) - Stripped raw candidate string: '$valuePart'");
        expiryDate = _parseDate(valuePart);
        if (expiryDate == null && i + 1 < lines.length) {
          log("OcrParser: Fallback Expiry (labeled) - Trying next line: '${lines[i + 1]}'");
          expiryDate = _parseDate(lines[i + 1]);
        }
      }

      if (batchNumber == null && _batchLabelRe.hasMatch(line)) {
        final valuePart = line
            .replaceAll(_batchLabelRe, '')
            .replaceAll(RegExp(r'^[\s:\-]+'), '')
            .trim();
        log("OcrParser: Fallback Batch - Stripped raw candidate string: '$valuePart'");
        final m = _batchToken.firstMatch(valuePart);
        if (m != null) {
          batchNumber = m.group(1);
          log("OcrParser: Fallback Batch - Succeeded on same line: $batchNumber");
        } else if (i + 1 < lines.length) {
          log("OcrParser: Fallback Batch - Trying next line: '${lines[i + 1]}'");
          final nm = _batchToken.firstMatch(lines[i + 1]);
          if (nm != null) {
            batchNumber = nm.group(1);
            log("OcrParser: Fallback Batch - Succeeded on next line: $batchNumber");
          }
        }
      }

      if (expiryDate != null && batchNumber != null) break;
    }

    return OcrParseResult(expiryDate: expiryDate, batchNumber: batchNumber);
  }

  // ── Date value parser ────────────────────────────────────────────────────

  /// Tries all date formats in priority order and returns the first match.
  static DateTime? _parseDate(String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return null;

    log("OcrParser: Validating date candidate text: '$cleanText'");

    RegExpMatch? match;
    DateTime? parsedDate;
    String? patternName;

    // --- High Priority: 3-segment dates (most specific) ---

    // Priority 1: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
    match = _ddmmyyyy.firstMatch(cleanText);
    if (match != null) {
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);
      if (day != null &&
          month != null &&
          year != null &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31 &&
          year >= 2000) {
        parsedDate = DateTime(year, month, day);
        patternName = "DD/MM/YYYY";
      }
    }
    if (parsedDate != null) {
      log("OcrParser: Validation SUCCESS - Pattern: $patternName, Matched: '${match!.group(0)}', Date: $parsedDate");
      return parsedDate;
    }

    // Priority 2: YYYY-MM-DD (ISO)
    match = _yyyymmdd.firstMatch(cleanText);
    if (match != null) {
      final year = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final day = int.tryParse(match.group(3)!);
      if (year != null &&
          month != null &&
          day != null &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31 &&
          year >= 2000) {
        parsedDate = DateTime(year, month, day);
        patternName = "YYYY-MM-DD";
      }
    }
    if (parsedDate != null) {
      log("OcrParser: Validation SUCCESS - Pattern: $patternName, Matched: '${match!.group(0)}', Date: $parsedDate");
      return parsedDate;
    }

    // Priority 3: DD/MM/YY, DD-MM-YY, DD.MM.YY (2-digit year)
    match = _ddmmyy.firstMatch(cleanText);
    if (match != null) {
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final yrShort = int.tryParse(match.group(3)!);
      if (day != null &&
          month != null &&
          yrShort != null &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31) {
        final year =
        (yrShort >= 0 && yrShort <= 50) ? (2000 + yrShort) : (1900 + yrShort);
        parsedDate = DateTime(year, month, day);
        patternName = "DD/MM/YY";
      }
    }
    if (parsedDate != null) {
      log("OcrParser: Validation SUCCESS - Pattern: $patternName, Matched: '${match!.group(0)}', Date: $parsedDate");
      return parsedDate;
    }

    // Priority 3b: DD/MMYY compact — handles OCR dropping the middle slash
    // in a DD/MM/YY date (e.g. "12/07/26" misread as "12/0726").
    match = _dMmyyCompact.firstMatch(cleanText);
    if (match != null) {
      final day = int.tryParse(match.group(1)!);
      final combined = match.group(2)!; // 4 digits: MM then YY
      final month = int.tryParse(combined.substring(0, 2));
      final yrShort = int.tryParse(combined.substring(2, 4));
      if (day != null &&
          month != null &&
          yrShort != null &&
          day >= 1 &&
          day <= 31 &&
          month >= 1 &&
          month <= 12) {
        final year =
        (yrShort >= 0 && yrShort <= 50) ? (2000 + yrShort) : (1900 + yrShort);
        parsedDate = DateTime(year, month, day);
        patternName = "DD/MMYY (compact)";
      }
    }
    if (parsedDate != null) {
      log("OcrParser: Validation SUCCESS - Pattern: $patternName, Matched: '${match!.group(0)}', Date: $parsedDate");
      return parsedDate;
    }

    // --- Medium Priority: Month Name & 6-digit codes ---

    // Priority 4: "MAR 2027" / "MARCH 2027"
    match = _monthNameYear.firstMatch(cleanText);
    if (match != null) {
      final monthKey = match.group(1)!.toUpperCase().substring(0, 3);
      final year = int.tryParse(match.group(2)!);
      final month = _monthMap[monthKey];
      if (month != null && year != null && year >= 2000) {
        parsedDate = DateTime(year, month, 1);
        patternName = "MonthName Year";
      }
    }
    if (parsedDate != null) {
      log("OcrParser: Validation SUCCESS - Pattern: $patternName, Matched: '${match!.group(0)}', Date: $parsedDate");
      return parsedDate;
    }

    // Priority 5: 6-digit code (DDMMYY, YYMMDD, MMDDYY)
    match = _sixDigits.firstMatch(cleanText);
    if (match != null) {
      final digits = match.group(1)!;
      log("OcrParser: Found 6-digit candidate: $digits. Disambiguating...");

      // Try DDMMYY (common Indian FMCG inkjet).
      final d1 = int.tryParse(digits.substring(0, 2));
      final m1 = int.tryParse(digits.substring(2, 4));
      final y1 = int.tryParse(digits.substring(4, 6));
      if (d1 != null && m1 != null && y1 != null) {
        final year = (y1 >= 0 && y1 <= 50) ? (2000 + y1) : (1900 + y1);
        if (m1 >= 1 && m1 <= 12 && d1 >= 1 && d1 <= 31 && year >= 1900 && year <= 2100) {
          parsedDate = DateTime(year, m1, d1);
          log("OcrParser: Validation SUCCESS - Pattern: 6-digit DDMMYY, Matched: '${match.group(0)}', Date: $parsedDate");
          return parsedDate;
        }
      }

      // Try YYMMDD.
      final y2 = int.tryParse(digits.substring(0, 2));
      final m2 = int.tryParse(digits.substring(2, 4));
      final d2 = int.tryParse(digits.substring(4, 6));
      if (y2 != null && m2 != null && d2 != null) {
        final year = (y2 >= 0 && y2 <= 50) ? (2000 + y2) : (1900 + y2);
        if (m2 >= 1 && m2 <= 12 && d2 >= 1 && d2 <= 31 && year >= 1900 && year <= 2100) {
          parsedDate = DateTime(year, m2, d2);
          log("OcrParser: Validation SUCCESS - Pattern: 6-digit YYMMDD, Matched: '${match.group(0)}', Date: $parsedDate");
          return parsedDate;
        }
      }

      // Try MMDDYY.
      final m3 = int.tryParse(digits.substring(0, 2));
      final d3 = int.tryParse(digits.substring(2, 4));
      final y3 = int.tryParse(digits.substring(4, 6));
      if (m3 != null && d3 != null && y3 != null) {
        final year = (y3 >= 0 && y3 <= 50) ? (2000 + y3) : (1900 + y3);
        if (m3 >= 1 && m3 <= 12 && d3 >= 1 && d3 <= 31 && year >= 1900 && year <= 2100) {
          parsedDate = DateTime(year, m3, d3);
          log("OcrParser: Validation SUCCESS - Pattern: 6-digit MMDDYY, Matched: '${match.group(0)}', Date: $parsedDate");
          return parsedDate;
        }
      }
      log("OcrParser: 6-digit candidate '$digits' failed all disambiguation checks.");
    }

    // --- Low Priority: 2-segment dates (with negative lookahead guards) ---

    // Priority 6: MM/YYYY — use last day of that month (with negative lookahead).
    match = _mmyyyy.firstMatch(cleanText);
    if (match != null) {
      final month = int.tryParse(match.group(1)!);
      final year = int.tryParse(match.group(2)!);
      if (month != null && year != null && month >= 1 && month <= 12 && year >= 2000) {
        final lastDay = DateTime(year, month + 1, 0).day;
        parsedDate = DateTime(year, month, lastDay);
        patternName = "MM/YYYY";
      }
    }
    if (parsedDate != null) {
      log("OcrParser: Validation SUCCESS - Pattern: $patternName, Matched: '${match!.group(0)}', Date: $parsedDate");
      return parsedDate;
    }

    // Priority 7: MM/YY (with slash) — use last day of that month (with negative lookahead).
    match = _mmyyWithSlash.firstMatch(cleanText);
    if (match != null) {
      final month = int.tryParse(match.group(1)!);
      final yrShort = int.tryParse(match.group(2)!);
      if (month != null && yrShort != null && month >= 1 && month <= 12) {
        final year =
        (yrShort >= 0 && yrShort <= 50) ? (2000 + yrShort) : (1900 + yrShort);
        final lastDay = DateTime(year, month + 1, 0).day;
        parsedDate = DateTime(year, month, lastDay);
        patternName = "MM/YY (slash)";
      }
    }
    if (parsedDate != null) {
      log("OcrParser: Validation SUCCESS - Pattern: $patternName, Matched: '${match!.group(0)}', Date: $parsedDate");
      return parsedDate;
    }

    // Priority 8: 4-digit code (MMYY) — use last day of that month.
    match = _fourDigits.firstMatch(cleanText);
    if (match != null) {
      final digits = match.group(1)!;
      final month = int.tryParse(digits.substring(0, 2));
      final yrShort = int.tryParse(digits.substring(2, 4));
      if (month != null && yrShort != null && month >= 1 && month <= 12) {
        final year =
        (yrShort >= 0 && yrShort <= 50) ? (2000 + yrShort) : (1900 + yrShort);
        final lastDay = DateTime(year, month + 1, 0).day;
        parsedDate = DateTime(year, month, lastDay);
        patternName = "MMYY (4-digit)";
      }
    }
    if (parsedDate != null) {
      log("OcrParser: Validation SUCCESS - Pattern: $patternName, Matched: '${match!.group(0)}', Date: $parsedDate");
      return parsedDate;
    }

    log("OcrParser: Validation FAILED for candidate text: '$cleanText'");
    return null;
  }
}

// ── Internal helper ──────────────────────────────────────────────────────────

class _SpatialCandidate {
  final String text;
  final double distance;
  const _SpatialCandidate(this.text, this.distance);
}