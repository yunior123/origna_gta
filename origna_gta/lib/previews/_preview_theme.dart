/// Shared preview theme helpers for Flutter Widget Previewer.
/// All preview functions import this to ensure consistent look.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// Dark 2100 theme used across all previews.
final ThemeData previewDarkTheme = ThemeData.dark().copyWith(
  colorScheme: ColorScheme.dark(primary: DesignTokens.primary, secondary: DesignTokens.secondary, error: DesignTokens.error, surface: DesignTokens.darkSurface),
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
  colorScheme: ColorScheme.light(primary: DesignTokens.primary, secondary: DesignTokens.secondary, surface: DesignTokens.surface),
  scaffoldBackgroundColor: DesignTokens.surface,
);

/// Preview wrapper for a row/grid of variants.
Widget previewGrid({required List<Widget> children, ThemeData? theme, Color? background, Locale locale = const Locale('en')}) {
  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('fr')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: locale,
    useOnlyLangCode: true,
    assetLoader: const _PreviewAssetLoader(),
    child: Builder(
      builder: (context) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme ?? previewDarkTheme,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            backgroundColor: background ?? DesignTokens.darkBackground,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < children.length; i++) ...[children[i], if (i < children.length - 1) const SizedBox(height: 16)],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Render a widget across all breakpoints simultaneously.
Widget previewResponsiveBreakpoints({
  required Widget Function(PreviewBreakpoint breakpoint) builder,
  ThemeData? theme,
  Color? background,
  Locale locale = const Locale('en'),
}) {
  Widget buildRow(String title, ThemeData rowTheme, Color rowBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: PreviewBreakpoint.values.map((bp) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${bp.name} (${bp.width.toInt()}x${bp.height.toInt()})',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: bp.width,
                      height: bp.height,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.3))),
                      child: ClipRect(
                        child: Theme(
                          data: rowTheme,
                          child: MediaQuery(
                            data: MediaQueryData(size: Size(bp.width, bp.height)),
                            child: Scaffold(backgroundColor: rowBg, body: builder(bp)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  return previewWrapper(
    locale: locale,
    theme: previewDarkTheme,
    background: const Color(0xff121212),
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (theme != null)
          buildRow('Custom Theme', theme, background ?? DesignTokens.darkBackground)
        else ...[
          buildRow('☀️ Light Mode', previewLightTheme, DesignTokens.surface),
          const Divider(height: 32, color: Colors.grey),
          buildRow('🌙 Dark Mode', previewDarkTheme, DesignTokens.darkBackground),
        ],
      ],
    ),
  );
}

/// Wrap a widget in MaterialApp + EasyLocalization for complete preview coverage.
Widget previewWrapper({
  required Widget child,
  ThemeData? theme,
  Color? background,
  EdgeInsets padding = const EdgeInsets.all(24),
  PreviewBreakpoint? breakpoint,
  Locale locale = const Locale('en'),
}) {
  Widget content = Center(
    child: SingleChildScrollView(padding: padding, child: child),
  );

  // Apply responsive constraint if breakpoint provided
  if (breakpoint != null) {
    content = Center(
      child: Container(
        width: breakpoint.width,
        height: breakpoint.height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black26)],
        ),
        child: ClipRect(
          child: MediaQuery(
            data: MediaQueryData(size: Size(breakpoint.width, breakpoint.height)),
            child: Scaffold(backgroundColor: background ?? DesignTokens.darkBackground, body: content),
          ),
        ),
      ),
    );
  } else {
    content = Scaffold(backgroundColor: background ?? DesignTokens.darkBackground, body: content);
  }

  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('fr')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: locale,
    useOnlyLangCode: true,
    // Use fallback loader to satisfy preview engine requirements
    assetLoader: const _PreviewAssetLoader(),
    child: Builder(
      builder: (context) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme ?? previewDarkTheme,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: content,
        );
      },
    ),
  );
}

/// Standard responsive breakpoints for previewing.
enum PreviewBreakpoint {
  mobileSm(width: 320, height: 568, name: 'Mobile Small'),
  mobile(width: 375, height: 812, name: 'Mobile'),
  tablet(width: 768, height: 1024, name: 'Tablet'),
  desktop(width: 1440, height: 900, name: 'Desktop');

  final double width;
  final double height;
  final String name;

  const PreviewBreakpoint({required this.width, required this.height, required this.name});
}

/// Mock asset loader prevents I/O errors during widget preview rendering
class _PreviewAssetLoader extends AssetLoader {
  const _PreviewAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {};
}
