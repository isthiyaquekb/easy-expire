import 'package:flutter/material.dart';

/// Typography variants mapped 1-to-1 from the Stitch/Tailwind config:
///
/// | Variant       | Size | Weight | LetterSpacing | LineHeight |
/// |---------------|------|--------|---------------|------------|
/// | headlineLg    | 24px | 700    | -0.02em       | 32px       |
/// | headlineMd    | 20px | 600    | -0.01em       | 28px       |
/// | bodyLg        | 16px | 400    |  0em          | 24px       |
/// | bodySm        | 14px | 400    |  0em          | 20px       |
/// | labelCaps     | 12px | 600    | +0.05em       | 16px       |
/// | statDisplay   | 32px | 700    | -0.03em       | 40px       |
enum AppTextVariant {
  headlineLg,
  headlineMd,
  bodyLg,
  bodySm,
  labelCaps,
  statDisplay,
}

/// A theme-aware text widget built from your Stitch design tokens.
/// Color falls back to the variant's semantic default when not provided.
///
/// Usage:
/// ```dart
/// // Heading — uses cs.primary by default
/// AppText('FreshManager', variant: AppTextVariant.headlineLg)
///
/// // Tagline — uses cs.onSurfaceVariant by default
/// AppText('Premium Inventory Precision', variant: AppTextVariant.bodySm)
///
/// // Custom color override
/// AppText('ERROR', variant: AppTextVariant.labelCaps, color: cs.error)
///
/// // Center aligned
/// AppText('Hello', variant: AppTextVariant.bodyLg, textAlign: TextAlign.center)
///
/// // Max lines + overflow
/// AppText(longText, variant: AppTextVariant.bodySm, maxLines: 2)
/// ```
class CommonAppText extends StatelessWidget {
  const CommonAppText(
      this.text, {
        super.key,
        required this.variant,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow = TextOverflow.ellipsis,
        this.softWrap = true,
      });

  final String text;
  final AppTextVariant variant;

  /// Override the default semantic color for this variant.
  final Color? color;

  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily ?? 'Poppins';

    final spec = _spec(variant);

    // Default color per variant — override with [color] param
    final resolvedColor = color ?? _defaultColor(variant, cs);

    return Text(
      // labelCaps is always uppercase
      variant == AppTextVariant.labelCaps ? text.toUpperCase() : text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? overflow : TextOverflow.clip,
      softWrap: softWrap,
      style: TextStyle(
        fontFamily: family,
        fontSize: spec.size,
        fontWeight: spec.weight,
        letterSpacing: spec.letterSpacing,
        height: spec.lineHeight / spec.size, // Flutter uses relative height
        color: resolvedColor,
      ),
    );
  }


  // ── Token specs ──────────────────────────────────────────────────────────
  static _TextSpec _spec(AppTextVariant v) => switch (v) {
    AppTextVariant.headlineLg  => _TextSpec(24, FontWeight.w700, -0.02 * 24, 32),
    AppTextVariant.headlineMd  => _TextSpec(20, FontWeight.w600, -0.01 * 20, 28),
    AppTextVariant.bodyLg      => _TextSpec(16, FontWeight.w400, 0,           24),
    AppTextVariant.bodySm      => _TextSpec(14, FontWeight.w400, 0,           20),
    AppTextVariant.labelCaps   => _TextSpec(12, FontWeight.w600, 0.05 * 12,  16),
    AppTextVariant.statDisplay => _TextSpec(32, FontWeight.w700, -0.03 * 32, 40),
  };

  // ── Semantic color defaults ──────────────────────────────────────────────
  static Color _defaultColor(AppTextVariant v, ColorScheme cs) => switch (v) {
    AppTextVariant.headlineLg  => cs.primary,
    AppTextVariant.headlineMd  => cs.onSurface,
    AppTextVariant.bodyLg      => cs.onSurface,
    AppTextVariant.bodySm      => cs.onSurfaceVariant,
    AppTextVariant.labelCaps   => cs.onSurfaceVariant,
    AppTextVariant.statDisplay => cs.onSurface,
  };
}

// Internal token holder
class _TextSpec {
  final double size;
  final FontWeight weight;
  final double letterSpacing;
  final double lineHeight;
  const _TextSpec(this.size, this.weight, this.letterSpacing, this.lineHeight);
}