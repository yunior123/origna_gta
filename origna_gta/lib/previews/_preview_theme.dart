/// Shared preview theme helpers for Flutter Widget Previewer.
/// All preview functions import this to ensure consistent look.
library;

import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// Dark 2100 theme used across all previews.
final ThemeData previewDarkTheme = ThemeData.dark().copyWith(
  colorScheme: ColorScheme.dark(
    primary: DesignTokens.primary,
    secondary: DesignTokens.secondary,
    error: DesignTokens.error,
    surface: DesignTokens.darkSurface,
  ),
  scaffoldBackgroundColor: DesignTokens.darkBackground,
  cardColor: DesignTokens.darkCard,
  dividerColor: DesignTokens.darkOutline,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
  ),
);

/// Light theme (used sparingly — app is primarily dark).
final ThemeData previewLightTheme = ThemeData.light().copyWith(
  colorScheme: ColorScheme.light(
    primary: DesignTokens.primary,
    secondary: DesignTokens.secondary,
    surface: DesignTokens.surface,
  ),
  scaffoldBackgroundColor: DesignTokens.surface,
);

/// Wrap a widget in MaterialApp + Scaffold for isolated rendering.
/// Uses dark theme by default (matches the OrignaGTA app).
Widget previewWrapper({
  required Widget child,
  ThemeData? theme,
  Color? background,
  EdgeInsets padding = const EdgeInsets.all(24),
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme ?? previewDarkTheme,
    home: Scaffold(
      backgroundColor: background ?? DesignTokens.darkBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: padding,
          child: child,
        ),
      ),
    ),
  );
}

/// Preview wrapper for a row/grid of variants.
Widget previewGrid({
  required List<Widget> children,
  ThemeData? theme,
  Color? background,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme ?? previewDarkTheme,
    home: Scaffold(
      backgroundColor: background ?? DesignTokens.darkBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    ),
  );
}
