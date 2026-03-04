/// Shared preview theme helpers for Flutter Widget Previewer.
/// All preview functions import this to ensure consistent look.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/utils/design_tokens.dart';

// ============================================================================
// THEMES
// ============================================================================

/// Dark theme used across all previews.
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

// ============================================================================
// FIREBASE-SAFE PROVIDER SCOPE
// ============================================================================

/// Central ProviderScope for previews — overrides all Firebase-dependent
/// providers so the widget previewer never calls Firebase.initializeApp().
/// Pass extra [overrides] for screen-specific mocks (e.g. a logged-in user).
Widget previewScope({required Widget child, List<Override> extraOverrides = const []}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(null)),
      userIdProvider.overrideWith((ref) => null),
      userRepositoryProvider.overrideWith((ref) => _PreviewUserRepository()),
      ...extraOverrides,
    ],
    child: child,
  );
}

/// Like [previewScope] but with a fake logged-in user id.
Widget previewScopeLoggedIn({required Widget child, String uid = 'preview-uid', List<Override> extraOverrides = const []}) {
  return previewScope(
    child: child,
    extraOverrides: [
      userIdProvider.overrideWith((ref) => uid),
      ...extraOverrides,
    ],
  );
}

// ============================================================================
// WRAPPERS
// ============================================================================

/// Wrap a widget in MaterialApp + EasyLocalization for complete preview coverage.
Widget previewWrapper({
  required Widget child,
  ThemeData? theme,
  Color? background,
  EdgeInsets padding = const EdgeInsets.all(24),
  PreviewBreakpoint? breakpoint,
  Locale locale = const Locale('en'),
}) {
  Widget content = SingleChildScrollView(padding: padding, child: child);

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
    content = Scaffold(backgroundColor: background ?? DesignTokens.darkBackground, body: Center(child: content));
  }

  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('fr')],
    path: 'packages/origna_gta/assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: locale,
    useOnlyLangCode: true,
    // No custom assetLoader — uses default RootBundleAssetLoader to read real translations
    child: Builder(
      builder: (context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme ?? previewDarkTheme,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: content,
      ),
    ),
  );
}

/// Preview wrapper for a row/grid of widget variants (no breakpoint sizing).
Widget previewGrid({required List<Widget> children, ThemeData? theme, Color? background, Locale locale = const Locale('en')}) {
  return previewWrapper(
    locale: locale,
    theme: theme,
    background: background,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const SizedBox(height: 16),
        ],
      ],
    ),
  );
}

// ============================================================================
// RESPONSIVE PREVIEWS
// ============================================================================

/// Shows a screen across Mobile, Tablet, and Desktop breakpoints — stacked
/// vertically. Each frame scales DOWN to fit the panel width (never upscales),
/// so all layouts are visible without horizontal overflow.
Widget previewResponsiveBreakpoints({
  required Widget Function(PreviewBreakpoint breakpoint) builder,
  ThemeData? theme,
  Color? background,
  Locale locale = const Locale('en'),
}) {
  final effectiveTheme = theme ?? previewDarkTheme;
  final effectiveBg = background ?? DesignTokens.darkBackground;

  // Only the three sizes that matter for layout decisions.
  const breakpoints = [PreviewBreakpoint.mobile, PreviewBreakpoint.tablet, PreviewBreakpoint.desktop];

  return previewWrapper(
    locale: locale,
    background: const Color(0xff121212),
    padding: const EdgeInsets.all(16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        // Panel width from LayoutBuilder; fall back to 400 if unbounded.
        final panelW = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final bp in breakpoints) ...[
              _label('${bp.name}  •  ${bp.width.toInt()}×${bp.height.toInt()}'),
              _scaledFrame(bp, panelW, effectiveTheme, effectiveBg, builder),
              const SizedBox(height: 32),
            ],
          ],
        );
      },
    ),
  );
}

/// Renders [bp] at its natural dimensions then scales it to fit [panelW].
/// Caps each frame at [_maxFrameH] so all three breakpoints fit without
/// excessive vertical scrolling in the widget previewer.
/// Never upscales (mobile stays at 375px on a wide panel).
const double _maxFrameH = 350;

Widget _scaledFrame(
  PreviewBreakpoint bp,
  double panelW,
  ThemeData theme,
  Color bg,
  Widget Function(PreviewBreakpoint) builder,
) {
  final scaleW = (panelW / bp.width).clamp(0.0, 1.0);
  final scaleH = (_maxFrameH / bp.height).clamp(0.0, 1.0);
  final scale = scaleW < scaleH ? scaleW : scaleH;
  final displayH = bp.height * scale;
  final displayW = bp.width * scale;

  return SizedBox(
    width: displayW,
    height: displayH,
    child: Transform.scale(
      scale: scale,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: bp.width,
        height: bp.height,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.3))),
          child: ClipRect(
            child: Theme(
              data: theme,
              child: MediaQuery(
                data: MediaQueryData(size: Size(bp.width, bp.height)),
                child: Scaffold(backgroundColor: bg, body: builder(bp)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Shows a screen across ALL breakpoints side by side — use when you explicitly
/// need multi-viewport comparison. Requires horizontal scrolling in the panel.
Widget previewAllBreakpoints({
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
        _label(title),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: PreviewBreakpoint.values.map((bp) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${bp.name} (${bp.width.toInt()}×${bp.height.toInt()})',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
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

// ============================================================================
// BREAKPOINTS
// ============================================================================

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

// ============================================================================
// INTERNALS
// ============================================================================

Widget _label(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
);

/// No-op UserRepository — prevents Firebase calls in previews.
class _PreviewUserRepository implements UserRepository {
  @override
  Future<String> addBuyerAddress(Address address) async => 'preview-addr-id';

  @override
  Future<void> deleteBuyerAddress(String addressId) async {}

  @override
  Future<SellerAccountStatus> getSellerAccountStatus(String userId) async =>
      const SellerAccountStatus(isSeller: false, chargesEnabled: false);

  @override
  Future<UserModel?> getUserProfile(String userId) async => null;

  @override
  Future<void> recordTermsAcceptance() async {}

  @override
  Future<void> setDefaultBuyerAddress(String addressId) async {}

  @override
  Future<void> updateBuyerAddress(String addressId, Address address) async {}

  @override
  Future<void> updateNotificationPreferences(
    String userId, {
    bool? notifyNewProducts,
    bool? notifyTrending,
  }) async {}

  @override
  Future<void> updatePreferredLanguage(String userId, String lang) async {}

  @override
  Stream<List<Address>> watchAddresses(String userId) => Stream.value([]);

  @override
  Stream<SellerAccountStatus> watchSellerAccountStatus(String userId) =>
      Stream.value(const SellerAccountStatus(isSeller: false, chargesEnabled: false));
}
