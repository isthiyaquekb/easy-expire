// Parses OCR output (RecognizedText) from product packaging and extracts
// expiry date and batch number.
//
// DESIGN — Three-phase strategy:
//   Phase 1 (spatial): Walk every TextLine in the RecognizedText block/line
//     structure. When a line's text matches a label pattern, search the full
//     set of lines for the nearest spatially-adjacent candidate — either on
//     the same row (similar Y-center) or directly below (next-row Y range).
//     Use the first candidate that yields a parseable value.
//   Phase 2 (fallback): If spatial search finds nothing, run regex directly
//     on the flattened .text string. This handles compact single-line labels
//     like "EXP: 12/2027" where label and value are in the same TextLine.
//   Phase 3 (unlabeled batch guess): If NO batch label was found anywhere on
//     the package (e.g. a bare code like "A1398" printed with no "BATCH" /
//     "LOT" / "B.NO" text near it), guess from an alphanumeric token that
//     mixes letters and digits, preferring the one spatially closest to a
//     detected date line. Lowest confidence tier — see [OcrFieldSource.unlabeledGuess].
//
// COORDINATE SYSTEM: boundingBox values are in image-sensor pixel space
//   (not screen pixels). Comparisons are purely relative (ratios) so they
//   are resolution-independent.
//
// This file has NO Flutter / platform imports so it works in plain dart test.

import 'dart:developer';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// ── Confidence / source ───────────────────────────────────────────────────────

/// How a field was found during parsing.
enum OcrFieldSource {
  /// Label + value were adjacent in the OCR block/line structure.
  spatial,

  /// Regex matched the flattened text string (lower confidence).
  fullTextFallback,

  /// No label was found anywhere on the package; the value was guessed
  /// from an unlabeled alphanumeric token (lowest confidence).
  unlabeledGuess,
}

// ── Result type ───────────────────────────────────────────────────────────────

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

  /// Whether any field was found only through a lower-confidence path
  /// (full-text fallback or an unlabeled guess).
  bool get hasLowConfidenceResult =>
      expirySource == OcrFieldSource.fullTextFallback ||
          expirySource == OcrFieldSource.unlabeledGuess ||
          batchSource == OcrFieldSource.fullTextFallback ||
          batchSource == OcrFieldSource.unlabeledGuess;

  /// Whether the batch field specifically came from an unlabeled guess —
  /// useful for UI callers that want to require extra confirmation before
  /// accepting it (e.g. a longer stability window).
  bool get batchIsUnlabeledGuess =>
      batchSource == OcrFieldSource.unlabeledGuess;

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

// ── Tunable spatial tolerances ────────────────────────────────────────────────
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

// ── Main parser ───────────────────────────────────────────────────────────────

abstract class OcrParser {
  OcrParser._();

  // ── Label regexes ─────────────────────────────────────────────────────────

  /// Matches expiry label lines (case-insensitive).
  /// Covers: EXP, EXP., EXPIRY, EXPIRY DATE, USE BY, BEST BEFORE, USE BY DATE
  static final _expiryLabelRe = RegExp(
    r'(?:BEST\s+BEFORE|USE\s+BY(?:\s+DATE)?|EXPIRY(?:\s+DATE)?|EXP(?:IRY)?\.?)',
    caseSensitive: false,
  );

  /// Matches batch label lines.
  /// Covers: BATCH, BATCH#, LOT, LOT:, LOT#, B.NO, B.NO., BN
  ///
  /// FIX: original pattern had a trailing \b only, which let LOT match
  /// mid-word (e.g. "PILOT", "PLOT-123") and made the match length
  /// inconsistent around trailing punctuation (e.g. "LOT No." vs "LOT No").
  /// Now anchored with a leading \b, and terminated with a lookahead for a
  /// sensible separator (colon, dot, dash, whitespace, or end of string)
  /// instead of relying on \b at the end.
  static final _batchLabelRe = RegExp(
    r'\b(?:BATCH\s*(?:NO\.?|NUMBER|#)?|LOT\s*(?:NO\.?|#)?|B\.?\s*NO\.?|BN)'
    r'(?=\s*[:.\-]?\s*)',
    caseSensitive: false,
  );

  /// Unlabeled batch code heuristic (Phase 3 only — see [_findUnlabeledBatch]).
  /// Matches alphanumeric tokens that mix at least one letter and one digit,
  /// 4–7 characters (typical FMCG batch code length, e.g. "A1398"). Pure-letter
  /// and pure-digit tokens are excluded (pure digits are usually dates/weights/
  /// barcodes; pure letters are ordinary words). The length window was tightened
  /// from 3–12 down to 4–7 after real-world testing showed 3-char tokens like
  /// "F85" (from a misread price "₹85/-") and 8-char tokens like "o9639900"
  /// (a barcode fragment) were being picked up as false positives.
  static final _unlabeledBatchRe = RegExp(
    r'\b(?=[A-Z0-9]*[A-Z])(?=[A-Z0-9]*[0-9])[A-Z0-9]{4,7}\b',
    caseSensitive: false,
  );

  /// Matches tokens that are actually a quantity + unit, e.g. "43lg" (OCR
  /// misread of "0.43kg" after the decimal point splits the token), "500g",
  /// "250ml". These pass [_unlabeledBatchRe]'s letter+digit test but are not
  /// batch codes, so they're filtered out explicitly before scoring.
  static final _quantityUnitRe = RegExp(
    r'^\d+\.?\d*(kg|gm|mg|g|ml|lg|lb|oz|l)$',
    caseSensitive: false,
  );

  /// Whether [line] looks like a price line (e.g. "F85/-", "₹85/-", "Rs.85"),
  /// which should never be searched for a batch candidate.
  static bool _looksLikePriceLine(String line) {
    return line.contains('/-') ||
        line.contains('₹') ||
        line.contains(r'$') ||
        RegExp(r'\bRs\.?\b', caseSensitive: false).hasMatch(line);
  }

  // ── Date patterns ─────────────────────────────────────────────────────────

  /// DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
  static final _ddmmyyyy = RegExp(
    r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})\b',
  );

  /// YYYY-MM-DD (ISO 8601)
  static final _yyyymmdd = RegExp(
    r'\b(\d{4})-(\d{2})-(\d{2})\b',
  );

  /// DD/MM/YY, DD-MM-YY, DD.MM.YY (new pattern for 2-digit year)
  static final _ddmmyy = RegExp(
    r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2})\b',
  );

  /// "MAR 2027", "MARCH 2027", "MAR2027", "Mar. 2027"
  static final _monthNameYear = RegExp(
    r'\b(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z]*\.?\s*(\d{4})\b',
    caseSensitive: false,
  );

  /// MM/YYYY or MM-YYYY (no explicit day)
  /// Added negative lookahead to prevent matching partial DD/MM/YYYY
  static final _mmyyyy = RegExp(
    r'\b(\d{2})[\/\-](\d{4})\b(?![/\-. ]?\d{1,4})',
  );

  /// MM/YY or MM-YY (no explicit day)
  /// Added negative lookahead to prevent matching partial DD/MM/YY
  static final _mmyyWithSlash = RegExp(
    r'\b(\d{2})[\/\-](\d{2})\b(?![/\-. ]?\d{1,4})',
  );

  /// DDMMYY (6 consecutive digits, no separators)
  static final _sixDigits = RegExp(
    r'\b(\d{6})\b',
  );

  /// MMYY (4 consecutive digits, no separators)
  static final _fourDigits = RegExp(
    r'\b(\d{4})\b',
  );

  // ── Batch value pattern ───────────────────────────────────────────────────

  /// Alphanumeric batch token, at least 2 chars, up to 20.
  static final _batchToken = RegExp(
    r'\b([A-Z0-9][A-Z0-9\-\/\.]{1,19})\b',
    caseSensitive: false,
  );

  // ── Month map ─────────────────────────────────────────────────────────────
  static const _monthMap = {
    'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
    'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
  };

  // ── Ignored batch words to avoid false positives ─────────────────────────
  static const _ignoredBatchWords = {
    'the', 'lot', 'no', 'mfg', 'exp', 'date', 'net', 'ref', 'for', 'and', 'of',
    'to', 'by', 'this', 'product', 'batch', 'number', 'use', 'before', 'best',
    'val', 'dt', 'co', 'in', 'is', 'it', 'at', 'an', 'as', 'on', 'or', 'with', 'refer', 'last', 'two'
  };

  /// Whether [word] should be treated as noise rather than a real batch
  /// value.
  ///
  /// IMPORTANT: any token containing a digit is treated as a real code and
  /// never ignored here. The previous version stripped digits before
  /// checking length, which meant a genuine code like "A1398" collapsed to
  /// just "a" (1 character) and was incorrectly flagged as ignored —
  /// silently discarding the correct batch number in every phase that
  /// calls this function (Phase 1 Case A/B, Phase 2 fallback, Phase 3).
  /// The ignore list below only makes sense for accidentally-matched plain
  /// English words, which are purely alphabetic by definition.
  static bool _isIgnoredBatchWord(String word) {
    if (RegExp(r'\d').hasMatch(word)) return false;
    final clean = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (clean.length <= 1) return true; // Ignore single letters or purely non-alpha
    return _ignoredBatchWords.contains(clean);
  }

  // ── Public entry point ────────────────────────────────────────────────────

  /// Parse [recognizedText] from ML Kit and return a typed [OcrParseResult].
  ///
  /// Delegates to [_spatialParse] first, then [_fallbackParse].
  static OcrParseResult parse(RecognizedText recognizedText) {
    // Flatten all TextLines across all blocks into one searchable list.
    final allLines = <TextLine>[];
    for (final block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }

    final result = _spatialParse(allLines, recognizedText.text);

    // --- Post-parsing Expiry Date Correction ---
    // On medicine packaging, MFG and EXP dates are frequently printed together.
    // If the spatial matching incorrectly selected the MFG date (which is earlier),
    // we can correct this by scanning the rest of the package for any later valid date,
    // which represents the actual Expiry Date.
    if (result.expiryDate != null) {
      DateTime latestDate = result.expiryDate!;
      OcrFieldSource finalSource = result.expirySource ?? OcrFieldSource.spatial;

      final allPossibleDates = <DateTime>[];
      for (final line in allLines) {
        final d = _parseDate(line.text);
        if (d != null) {
          allPossibleDates.add(d);
        }
      }

      for (final d in allPossibleDates) {
        if (d.isAfter(latestDate)) {
          log("OcrParser: Post-parse correction - Found a later date '$d' than detected expiry '$latestDate'. Correcting expiry date to the later one.");
          latestDate = d;
          finalSource = OcrFieldSource.spatial;
        }
      }

      return OcrParseResult(
        expiryDate: latestDate,
        expirySource: finalSource,
        batchNumber: result.batchNumber,
        batchSource: result.batchSource,
      );
    }

    return result;
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

      // ── Expiry ────────────────────────────────────────────────────────────
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

      // ── Batch ─────────────────────────────────────────────────────────────
      if (batchNumber == null && _batchLabelRe.hasMatch(labelText)) {
        // Case A: value on same line after stripping label.
        final stripped = labelText.replaceAll(_batchLabelRe, '')
            .replaceAll(RegExp(r'^[\s:\-]+'), '')
            .trim();
        log("OcrParser: Spatial Batch Case A - Stripped raw candidate string: '$stripped'");
        final inlineBatch = _batchToken.firstMatch(stripped)?.group(1);
        if (inlineBatch != null && inlineBatch.isNotEmpty && !_isIgnoredBatchWord(inlineBatch)) {
          batchNumber = inlineBatch;
          batchSource = OcrFieldSource.spatial;
          log("OcrParser: Spatial Batch Case A - Succeeded. Batch: $batchNumber");
        } else {
          log("OcrParser: Spatial Batch Case A - Validation failed or ignored for '$stripped'. Trying Case B...");
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
              if (isMatch) {
                final matchVal = _batchToken.firstMatch(clean)?.group(1);
                if (matchVal != null && _isIgnoredBatchWord(matchVal)) {
                  log("OcrParser: Spatial Batch Case B - Candidate '$clean' rejected because it matches ignored batch word.");
                  return false;
                }
              }
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

    // ── Phase 2: full-text fallback ───────────────────────────────────────
    final fallback = _fallbackParse(fullText);

    expiryDate ??= fallback.expiryDate;
    expirySource ??= fallback.expiryDate != null
        ? OcrFieldSource.fullTextFallback
        : null;

    batchNumber ??= fallback.batchNumber;
    batchSource ??= fallback.batchNumber != null
        ? OcrFieldSource.fullTextFallback
        : null;

    // ── Phase 3: unlabeled batch guess ──────────────────────────────────────
    // Only runs when NO batch label was found anywhere on the package (Phase 1
    // and Phase 2 both came up empty). Handles packages like a jam jar that
    // print a bare code (e.g. "A1398") with no "BATCH"/"LOT"/"B.NO" text at all.
    if (batchNumber == null) {
      // Prefer anchoring near whichever line produced the expiry date, since
      // batch codes are typically printed close to the date block. Falls back
      // to unanchored (first-in-reading-order) scoring if no date was found.
      TextLine? anchor;
      if (expiryDate != null) {
        for (final line in allLines) {
          if (_parseDate(line.text) != null) {
            anchor = line;
            break;
          }
        }
      }
      final guess = _findUnlabeledBatch(allLines, anchorLine: anchor);
      if (guess != null) {
        batchNumber = guess;
        batchSource = OcrFieldSource.unlabeledGuess;
        log("OcrParser: Phase 3 - Unlabeled batch guess: $batchNumber");
      } else {
        log("OcrParser: Phase 3 - No unlabeled batch candidate found.");
      }
    }

    return OcrParseResult(
      expiryDate: expiryDate,
      expirySource: expirySource,
      batchNumber: batchNumber,
      batchSource: batchSource,
    );
  }

  // ── Phase 3: unlabeled batch heuristic ────────────────────────────────────

  /// Searches [allLines] for a bare alphanumeric token that looks like a
  /// batch code, with no label ("BATCH"/"LOT"/"B.NO"/etc.) anywhere near it.
  ///
  /// Rules:
  ///   - Skips lines that themselves parse as a date, or that match the
  ///     expiry/batch label regexes (avoids re-guessing a label word itself).
  ///   - Skips pure-numeric and known "ignored" tokens.
  ///   - If [anchorLine] is provided (typically the line containing the
  ///     detected expiry/mfg date), scores candidates by spatial distance
  ///     from it and returns the closest match — batch codes are usually
  ///     printed near the date block on FMCG packaging.
  ///   - If no anchor is available, returns the first valid candidate in
  ///     reading order.
  static String? _findUnlabeledBatch(
      List<TextLine> allLines, {
        TextLine? anchorLine,
      }) {
    _TokenCandidate? best;

    for (final line in allLines) {
      final text = line.text.trim();
      if (text.isEmpty) continue;

      // Skip lines that are themselves a date, or that carry a known label —
      // we don't want to re-interpret "EXP" or "12/2027" as a batch code.
      if (_parseDate(line.text) != null) continue;
      if (_expiryLabelRe.hasMatch(text) || _batchLabelRe.hasMatch(text)) {
        continue;
      }
      // Skip price lines entirely (e.g. "F85/-", "₹85/-") — a price digit
      // run can otherwise look identical to a short batch-like token.
      if (_looksLikePriceLine(text)) {
        log("OcrParser: Phase 3 - Skipping price-like line: '$text'");
        continue;
      }

      for (final match in _unlabeledBatchRe.allMatches(text)) {
        final token = match.group(0)!;
        if (_isIgnoredBatchWord(token)) continue;
        // Reject quantity+unit tokens, e.g. "43lg" (OCR misread of "0.43kg").
        if (_quantityUnitRe.hasMatch(token)) {
          log("OcrParser: Phase 3 - Rejecting quantity/unit token: '$token'");
          continue;
        }

        double score = _shapePenalty(token);
        if (anchorLine != null) {
          final dY = (line.boundingBox.center.dy -
              anchorLine.boundingBox.center.dy)
              .abs();
          final dX = (line.boundingBox.center.dx -
              anchorLine.boundingBox.center.dx)
              .abs();
          // Weight vertical proximity more heavily — batch/date pairs are
          // usually stacked in the same column more often than side by side.
          score += dY * 3.0 + dX;
        }

        log("OcrParser: Phase 3 - Candidate '$token' from line '$text', score: $score");
        if (best == null || score < best.score) {
          best = _TokenCandidate(token, score);
        }
      }
    }

    return best?.token;
  }

  /// Scores how "batch-code-shaped" a token is. Lower is more likely to be
  /// a real batch code. Real-world FMCG batch codes are overwhelmingly a
  /// short letter prefix followed by digits (e.g. "A1398", "L045"); digits
  /// followed by letters, or long digit-heavy tokens with a single stray
  /// leading letter (e.g. "o9639900", likely a barcode/reference fragment),
  /// are penalized so they lose to a proper candidate when both are present.
  static double _shapePenalty(String token) {
    if (RegExp(r'^[A-Za-z]{1,2}\d{2,5}$').hasMatch(token)) return 0; // e.g. A1398
    if (RegExp(r'^[A-Za-z]\d{5,}$').hasMatch(token)) return 20; // e.g. o9639900
    if (RegExp(r'^\d+[A-Za-z]{1,2}$').hasMatch(token)) return 10; // e.g. 1398A
    return 15; // interleaved / irregular shape
  }

  // ── Spatial adjacency search ──────────────────────────────────────────────

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
      final text = line.text.trim();
      if (text.isEmpty || !valueCheck(text)) continue;

      final candidateCenterY = box.center.dy;
      final dY = (candidateCenterY - labelCenterY).abs();

      // ── Same-row check ───────────────────────────────────────────────────
      // Two lines are on the same row when their Y-centers are within
      // kSameRowYTolerance × label height of each other.
      if (dY < labelHeight * kSameRowYTolerance) {
        final dX = box.left - labelBox.right; // positive = to the right
        if (dX >= 0) {
          // Right of label — prefer closest horizontal distance.
          // In column-alignment layouts, multiple values can have the exact same dX.
          // To disambiguate and vertically align correctly, we use a combined score
          // that heavily weights vertical proximity (dY).
          final score = dX + (dY * 3.0);
          if (bestSameRowRight == null || score < bestSameRowRight.distance) {
            bestSameRowRight = _SpatialCandidate(text, score);
          }
        } else {
          // Left of label — less preferred.
          final leftDist = (labelBox.left - box.right).abs();
          final score = leftDist + (dY * 3.0);
          if (bestSameRowLeft == null || score < bestSameRowLeft.distance) {
            bestSameRowLeft = _SpatialCandidate(text, score);
          }
        }
        continue;
      }

      // ── Below check ──────────────────────────────────────────────────────
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
        final score = gapBelow + (xDiff * 2.0);
        if (bestBelow == null || score < bestBelow.distance) {
          bestBelow = _SpatialCandidate(text, score);
        }
      }
    }

    // Return in priority order.
    return bestSameRowRight?.text ?? bestBelow?.text ?? bestSameRowLeft?.text;
  }

  // ── Phase 2: full-text fallback ───────────────────────────────────────────

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
    // before passing the entire noisy string to _parseDate
    final dateCandidates = <String>[];
    dateCandidates.addAll(lines);
    final allDigitsRegex = RegExp(r'\b(\d{4}|\d{6})\b'); // Find 4 or 6 digit numbers
    for (final match in allDigitsRegex.allMatches(fullText)) {
      dateCandidates.add(match.group(0)!);
    }

    // Try parsing each candidate
    for (final candidate in dateCandidates) {
      expiryDate = _parseDate(candidate);
      if (expiryDate != null) {
        log("OcrParser: Fallback Expiry - Succeeded with candidate: '$candidate'. Date: $expiryDate");
        break;
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Re-check expiry with label if not found yet (just in case)
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
        if (m != null && !_isIgnoredBatchWord(m.group(1)!)) {
          batchNumber = m.group(1);
          log("OcrParser: Fallback Batch - Succeeded on same line: $batchNumber");
        } else if (i + 1 < lines.length) {
          log("OcrParser: Fallback Batch - Trying next line: '${lines[i + 1]}'");
          final nm = _batchToken.firstMatch(lines[i + 1]);
          if (nm != null && !_isIgnoredBatchWord(nm.group(1)!)) {
            batchNumber = nm.group(1);
            log("OcrParser: Fallback Batch - Succeeded on next line: $batchNumber");
          }
        }
      }

      if (expiryDate != null && batchNumber != null) break;
    }

    return OcrParseResult(expiryDate: expiryDate, batchNumber: batchNumber);
  }

  // ── Date value parser ─────────────────────────────────────────────────────

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
      if (day != null && month != null && year != null &&
          month >= 1 && month <= 12 && day >= 1 && day <= 31 &&
          year >= 2000 && year <= 2045) {
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
      if (year != null && month != null && day != null &&
          month >= 1 && month <= 12 && day >= 1 && day <= 31 &&
          year >= 2000 && year <= 2045) {
        parsedDate = DateTime(year, month, day);
        patternName = "YYYY-MM-DD";
      }
    }
    if (parsedDate != null) {
      log("OcrParser: Validation SUCCESS - Pattern: $patternName, Matched: '${match!.group(0)}', Date: $parsedDate");
      return parsedDate;
    }

    // Priority 3: DD/MM/YY, DD-MM-YY, DD.MM.YY (new 2-digit year)
    match = _ddmmyy.firstMatch(cleanText);
    if (match != null) {
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final yrShort = int.tryParse(match.group(3)!);
      if (day != null && month != null && yrShort != null &&
          month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        final year = 2000 + yrShort;
        if (year >= 2000 && year <= 2045) {
          parsedDate = DateTime(year, month, day);
          patternName = "DD/MM/YY";
        }
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
      if (month != null && year != null && year >= 2000 && year <= 2045) {
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

      // Try DDMMYY (common Indian FMCG inkjet)
      final d1 = int.tryParse(digits.substring(0, 2));
      final m1 = int.tryParse(digits.substring(2, 4));
      final y1 = int.tryParse(digits.substring(4, 6));
      if (d1 != null && m1 != null && y1 != null) {
        final year = 2000 + y1;
        if (m1 >= 1 && m1 <= 12 && d1 >= 1 && d1 <= 31 && year >= 2000 && year <= 2045) {
          parsedDate = DateTime(year, m1, d1);
          log("OcrParser: Validation SUCCESS - Pattern: 6-digit DDMMYY, Matched: '${match.group(0)}', Date: $parsedDate");
          return parsedDate;
        }
      }

      // Try YYMMDD
      final y2 = int.tryParse(digits.substring(0, 2));
      final m2 = int.tryParse(digits.substring(2, 4));
      final d2 = int.tryParse(digits.substring(4, 6));
      if (y2 != null && m2 != null && d2 != null) {
        final year = 2000 + y2;
        if (m2 >= 1 && m2 <= 12 && d2 >= 1 && d2 <= 31 && year >= 2000 && year <= 2045) {
          parsedDate = DateTime(year, m2, d2);
          log("OcrParser: Validation SUCCESS - Pattern: 6-digit YYMMDD, Matched: '${match.group(0)}', Date: $parsedDate");
          return parsedDate;
        }
      }

      // Try MMDDYY
      final m3 = int.tryParse(digits.substring(0, 2));
      final d3 = int.tryParse(digits.substring(2, 4));
      final y3 = int.tryParse(digits.substring(4, 6));
      if (m3 != null && d3 != null && y3 != null) {
        final year = 2000 + y3;
        if (m3 >= 1 && m3 <= 12 && d3 >= 1 && d3 <= 31 && year >= 2000 && year <= 2045) {
          parsedDate = DateTime(year, m3, d3);
          log("OcrParser: Validation SUCCESS - Pattern: 6-digit MMDDYY, Matched: '${match.group(0)}', Date: $parsedDate");
          return parsedDate;
        }
      }
      log("OcrParser: 6-digit candidate '$digits' failed all disambiguation checks.");
    }

    // --- Low Priority: 2-segment dates (with negative lookahead guards) ---

    // Priority 6: MM/YYYY — use last day of that month (with negative lookahead)
    match = _mmyyyy.firstMatch(cleanText);
    if (match != null) {
      final month = int.tryParse(match.group(1)!);
      final year = int.tryParse(match.group(2)!);
      if (month != null && year != null &&
          month >= 1 && month <= 12 && year >= 2000 && year <= 2045) {
        final lastDay = DateTime(year, month + 1, 0).day;
        parsedDate = DateTime(year, month, lastDay);
        patternName = "MM/YYYY";
      }
    }
    if (parsedDate != null) {
      log("OcrParser: Validation SUCCESS - Pattern: $patternName, Matched: '${match!.group(0)}', Date: $parsedDate");
      return parsedDate;
    }

    // Priority 7: MM/YY (with slash) — use last day of that month (with negative lookahead)
    match = _mmyyWithSlash.firstMatch(cleanText);
    if (match != null) {
      final month = int.tryParse(match.group(1)!);
      final yrShort = int.tryParse(match.group(2)!);
      if (month != null && yrShort != null && month >= 1 && month <= 12) {
        final year = 2000 + yrShort;
        if (year >= 2000 && year <= 2045) {
          final lastDay = DateTime(year, month + 1, 0).day;
          parsedDate = DateTime(year, month, lastDay);
          patternName = "MM/YY (slash)";
        }
      }
    }
    if (parsedDate != null) {
      log("OcrParser: Validation SUCCESS - Pattern: $patternName, Matched: '${match!.group(0)}', Date: $parsedDate");
      return parsedDate;
    }

    // Priority 8: 4-digit code (MMYY) — use last day of that month
    match = _fourDigits.firstMatch(cleanText);
    if (match != null) {
      final digits = match.group(1)!;
      final month = int.tryParse(digits.substring(0, 2));
      final yrShort = int.tryParse(digits.substring(2, 4));
      if (month != null && yrShort != null && month >= 1 && month <= 12) {
        final year = 2000 + yrShort;
        if (year >= 2000 && year <= 2045) {
          final lastDay = DateTime(year, month + 1, 0).day;
          parsedDate = DateTime(year, month, lastDay);
          patternName = "MMYY (4-digit)";
        }
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

// ── Internal helpers ────────────────────────────────────────────────────────

class _SpatialCandidate {
  final String text;
  final double distance;
  const _SpatialCandidate(this.text, this.distance);
}

class _TokenCandidate {
  final String token;
  final double score;
  const _TokenCandidate(this.token, this.score);
}