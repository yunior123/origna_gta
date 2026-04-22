import 'dart:ui';

import 'package:flutter/material.dart';

class ThemeConfig {
  static const Color primary = Color(0xFF14213D);
  static const Color primaryLight = Color(0xFF1F325A);
  static const Color primaryDark = Color(0xFF0A162D);
  static const Color secondary = Color(0xFF2C4B87);
  static const Color tertiary = Color(0xFFD4A017);
  static const Color accent = Color(0xFF3FA7D6);
  static const Color gold = Color(0xFFD4A017);
  static const Color digital = Color(0xFF0F766E);

  static const Color surface = Color(0xFFF4F1EA);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8E2D7);
  static const Color divider = Color(0xFFD7D0C3);

  static const Color darkBackground = Color(0xFF08111F);
  static const Color darkSurface = Color(0xFF0F1D33);
  static const Color darkCard = Color(0xFF14233D);
  static const Color darkBorder = Color(0xFF243754);
  static const Color darkBackground2 = Color(0xFF0C172A);

  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF475467);
  static const Color textMuted = Color(0xFF667085);

  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFF818CF8);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF08111F), Color(0xFF14213D), Color(0xFF2C4B87)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0xFF14213D), Color(0xFF2C4B87), Color(0xFFD4A017)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient popularCardGradient = LinearGradient(
    colors: [Color(0xFF14213D), Color(0xFF1B335C), Color(0xFF0F1D33)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData lightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        surface: surface,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      fontFamily: 'Inter',
      cardTheme: const CardThemeData(
        color: surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        surface: darkSurface,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'Inter',
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double? opacity;
  final double blur;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.color,
    this.opacity,
    this.blur = 16.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(20.0)),
    this.padding = const EdgeInsets.all(20.0),
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor =
        color ?? (isDark ? const Color(0xFF161636) : Colors.white);
    final resolvedOpacity = opacity ?? (isDark ? 0.75 : 0.90);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: resolvedColor.withValues(alpha: resolvedOpacity),
            borderRadius: borderRadius,
            border: border ??
                Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.6),
                  width: 1,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final TextStyle? style;
  final TextAlign? textAlign;

  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient
          .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}
