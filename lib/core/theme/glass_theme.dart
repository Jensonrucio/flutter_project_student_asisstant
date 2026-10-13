import 'dart:ui';

import 'package:flutter/material.dart';

class GlassTheme {
  static const Color primaryDark = Color(0xFF0B1220);
  static const Color accentNeon = Color(0xFF818CF8);
  static const Color cyanAccent = Color(0xFF2DD4BF);

  static BoxDecoration glassBoxDecoration({double borderRadius = 20}) {
    return BoxDecoration(
      color: const Color(0xFF142033).withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static Widget glassContainer({
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
          decoration: glassBoxDecoration(borderRadius: borderRadius),
          child: child,
        ),
      ),
    );
  }
}
