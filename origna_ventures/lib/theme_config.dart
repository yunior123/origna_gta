import 'dart:ui';

import 'package:flutter/material.dart';

class ThemeConfig {
  static const Color primary = Color(0xFF7B93FF);
  static const Color secondary = Color(0xFF764BA2);
  static const Color tertiary = Color(0xFFFF6B6B);
  static const Color accent = Color(0xFF5CE1E6);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color gradientStart = Color(0xFF1F235A);
  static const Color gradientEnd = Color(0xFF764BA2);
  static const Color darkBackground = Color(0xFF0F0F1E);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static ThemeData lightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      fontFamily: 'Inter',
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'Inter',
    );
  }
}

/// Glassmorphism container — matches OrignaGTA's GlassContainer pattern.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double? opacity;
  final double blur;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.color,
    this.opacity,
    this.blur = 15.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(16.0)),
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor =
        color ?? (isDark ? const Color(0xFF1E1E32) : const Color(0xFFF3F4F9));
    final resolvedOpacity = opacity ?? (isDark ? 0.7 : 0.85);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: resolvedColor.withValues(alpha: resolvedOpacity),
            borderRadius: borderRadius,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
