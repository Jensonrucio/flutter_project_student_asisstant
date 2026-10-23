import 'dart:ui';

import 'package:flutter/material.dart';

class GlassTheme {
  static const Color primaryDark = Color(0xFF04132C);
  static const Color surfaceDark = Color(0xFF334155);
  static const Color accentNeon = Color(0xFF818CF8);
  static const Color cyanAccent = Color(0xFF2DD4BF);

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? primaryDark
      : const Color(0xFFF4F7FB);

  static Color foreground(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static BoxDecoration glassBoxDecoration(
    BuildContext context, {
    double borderRadius = 20,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: (isDark ? surfaceDark : Colors.white)
          .withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (isDark ? Colors.white : const Color(0xFF26354A))
            .withValues(alpha: isDark ? 0.09 : 0.1),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static Widget glassContainer({
    required BuildContext context,
    required Widget child,
    double borderRadius = 20,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: glassBoxDecoration(context, borderRadius: borderRadius),
          child: child,
        ),
      ),
    );
  }
}
