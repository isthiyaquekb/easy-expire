import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.isEnabled = true,
    this.inputType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.toggleChange,
    this.focusNode,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?) validator;

  /// Path to an SVG asset e.g. 'assets/icons/mail.svg'
  final String? prefixIcon;
  final String? suffixIcon;

  final bool isPassword;
  final bool isEnabled;
  final TextInputType inputType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? toggleChange;
  final FocusNode? focusNode;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Input fill — slightly offset from scaffold so it reads as a surface
    final inputFill = isDark
        ? const Color(0xFF111111)
        : const Color(0xFFF7F8FA);

    // Border colors
    final defaultBorder = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE0E0E0);

    // Icon color
    final iconColor = isEnabled
        ? cs.primary
        : cs.onSurface.withOpacity(0.38);

    final radius = BorderRadius.circular(10);

    Widget? prefix;
    if (prefixIcon != null) {
      prefix = Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SvgPicture.asset(
          prefixIcon!,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          height: 18,
          width: 18,
          fit: BoxFit.scaleDown,
        ),
      );
    }
    Widget? suffix;
    if (suffixIcon != null) {
      suffix = InkWell(
        onTap: toggleChange,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SvgPicture.asset(
            suffixIcon!,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            height: 18,
            width: 18,
            fit: BoxFit.scaleDown,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label above field ──────────────────────────────────────────
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: cs.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 6),

        // ── Input field ────────────────────────────────────────────────
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: isEnabled,
          obscureText: isPassword,
          keyboardType: isPassword ? TextInputType.visiblePassword : inputType,
          textInputAction: maxLines > 1 ? TextInputAction.newline : textInputAction,
          maxLines: isPassword ? 1 : maxLines,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.35),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            prefixIcon: prefix,
            suffixIcon: suffix,
            // No labelText — label is the Text widget above
            border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: defaultBorder, width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: defaultBorder, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: cs.primary, width: 1.5)),
            disabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: defaultBorder.withOpacity(0.4), width: 0.5)),
            errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: cs.error, width: 0.5)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: cs.error, width: 1.5)),
            errorStyle: TextStyle(color: cs.error, fontSize: 11),
          ),
        ),
      ],
    );
  }
}