import 'package:easyexpire/widgets/common_app_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
class AppSpan {
  const AppSpan(
      this.text, {
        this.variant,
        this.color,
        this.bold = false,
        this.onTap,
        this.underline = false,
      });

  final String text;
  final AppTextVariant? variant;
  final Color? color;
  final bool bold;
  final VoidCallback? onTap;
  final bool underline;
}

class AppRichText extends StatelessWidget {
  const AppRichText({
    super.key,
    required this.spans,
    this.baseVariant = AppTextVariant.bodySm,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  final List<AppSpan> spans;

  /// The default variant applied to all spans that don't specify their own.
  final AppTextVariant baseVariant;

  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily ?? 'Poppins';

    return RichText(
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? overflow : TextOverflow.clip,
      text: TextSpan(
        children: spans.map((span) => _buildSpan(span, cs, family)).toList(),
      ),
    );
  }

  InlineSpan _buildSpan(AppSpan span, ColorScheme cs, String family) {
    final variant = span.variant ?? baseVariant;
    final spec    = AppTextSpec.of(variant);

    final color = span.color ?? AppTextSpec.defaultColor(variant, cs);

    final style = TextStyle(
      fontFamily: family,
      fontSize: spec.size,
      fontWeight: span.bold ? FontWeight.w700 : spec.weight,
      letterSpacing: spec.letterSpacing,
      height: spec.lineHeight / spec.size,
      color: color,
      decoration: span.underline ? TextDecoration.underline : TextDecoration.none,
      decorationColor: color,
    );

    if (span.onTap != null) {
      return TextSpan(
        text: span.text,
        style: style,
        recognizer: TapGestureRecognizer()..onTap = span.onTap,
      );
    }

    return TextSpan(text: span.text, style: style);
  }
}

class AppTextSpec {
  final double size;
  final FontWeight weight;
  final double letterSpacing;
  final double lineHeight;

  const AppTextSpec(this.size, this.weight, this.letterSpacing, this.lineHeight);

  static AppTextSpec of(AppTextVariant v) => switch (v) {
    AppTextVariant.headlineLg  => const AppTextSpec(24, FontWeight.w700, -0.48, 32),
    AppTextVariant.headlineMd  => const AppTextSpec(20, FontWeight.w600, -0.20, 28),
    AppTextVariant.bodyLg      => const AppTextSpec(16, FontWeight.w400,  0.00, 24),
    AppTextVariant.bodySm      => const AppTextSpec(14, FontWeight.w400,  0.00, 20),
    AppTextVariant.labelCaps   => const AppTextSpec(12, FontWeight.w600,  0.60, 16),
    AppTextVariant.statDisplay => const AppTextSpec(32, FontWeight.w700, -0.96, 40),
  };

  static Color defaultColor(AppTextVariant v, ColorScheme cs) => switch (v) {
    AppTextVariant.headlineLg  => cs.primary,
    AppTextVariant.headlineMd  => cs.onSurface,
    AppTextVariant.bodyLg      => cs.onSurface,
    AppTextVariant.bodySm      => cs.onSurfaceVariant,
    AppTextVariant.labelCaps   => cs.onSurfaceVariant,
    AppTextVariant.statDisplay => cs.onSurface,
  };
}