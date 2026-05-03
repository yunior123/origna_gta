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
import 'package:flutter/widget_previews.dart';

// ============================================================================
// THEMES
// ============================================================================

/// Dark theme used across all previews.
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
  textTheme: TextTheme(
    bodyLarge: const TextStyle(color: DesignTokens.white),
    bodyMedium: TextStyle(color: DesignTokens.white.withValues(alpha: 0.7)),
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

// ============================================================================
// SELF-HOSTED BACKEND-SAFE PROVIDER SCOPE
// ============================================================================

/// Central ProviderScope for previews — overrides backend-dependent
/// providers so the widget previewer never performs live initialization.
/// Pass extra [overrides] for screen-specific mocks (e.g. a logged-in user).
Widget previewScope({
  required Widget child,
  List<Override> extraOverrides = const [],
}) {
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
Widget previewScopeLoggedIn({
  required Widget child,
  String uid = 'preview-uid',
  List<Override> extraOverrides = const [],
}) {
  return previewScope(
    child: child,
    extraOverrides: [
      userIdProvider.overrideWith((ref) => uid),
      ...extraOverrides,
    ],
  );
}

// ============================================================================
// BREAKPOINTS
// ============================================================================

enum _FrameType { phone, tablet, browser }

enum PreviewBreakpoint {
  mobileSm(width: 320, height: 568, name: 'Mobile S'),
  mobile(width: 390, height: 844, name: 'Mobile'),
  tablet(width: 768, height: 1024, name: 'Tablet'),
  desktop(width: 1280, height: 800, name: 'Desktop'),
  web(width: 1440, height: 900, name: 'Web');

  final double width;
  final double height;
  final String name;

  const PreviewBreakpoint({
    required this.width,
    required this.height,
    required this.name,
  });
}

_FrameType _frameTypeOf(PreviewBreakpoint bp) => switch (bp) {
  PreviewBreakpoint.mobileSm || PreviewBreakpoint.mobile => _FrameType.phone,
  PreviewBreakpoint.tablet => _FrameType.tablet,
  PreviewBreakpoint.desktop || PreviewBreakpoint.web => _FrameType.browser,
};

// ============================================================================
// DEVICE FRAME OVERLAY — painted on top of content at exact viewport size
// ============================================================================

/// Overlays device chrome on top of content within the viewport bounds.
class _DeviceFrameOverlay extends StatelessWidget {
  const _DeviceFrameOverlay({
    required this.breakpoint,
    required this.child,
    this.isDark = true,
  });

  final PreviewBreakpoint breakpoint;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return switch (_frameTypeOf(breakpoint)) {
      _FrameType.phone => _PhoneOverlay(
        width: breakpoint.width,
        height: breakpoint.height,
        isDark: isDark,
        child: child,
      ),
      _FrameType.tablet => _TabletOverlay(
        width: breakpoint.width,
        height: breakpoint.height,
        isDark: isDark,
        child: child,
      ),
      _FrameType.browser => _BrowserOverlay(
        width: breakpoint.width,
        height: breakpoint.height,
        isDark: isDark,
        child: child,
      ),
    };
  }
}

/// Phone chrome overlay: notch pill at top, home indicator at bottom, rounded corners.
class _PhoneOverlay extends StatelessWidget {
  const _PhoneOverlay({
    required this.width,
    required this.height,
    required this.child,
    this.isDark = true,
  });
  final double width;
  final double height;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Content (full viewport)
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: SizedBox.expand(child: child),
          ),
          // Phone chrome overlays
          CustomPaint(
            size: Size(width, height),
            painter: _PhoneChromePainter(
              width: width,
              height: height,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneChromePainter extends CustomPainter {
  _PhoneChromePainter({
    required this.width,
    required this.height,
    this.isDark = true,
  });
  final double width;
  final double height;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = isDark ? DesignTokens.darkOutline : DesignTokens.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final notchPaint = Paint()
      ..color = isDark ? DesignTokens.darkBackground : DesignTokens.surface;
    final homeBarPaint = Paint()
      ..color = isDark
          ? DesignTokens.white.withAlpha(100)
          : DesignTokens.black.withAlpha(40)
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;
    final shadowPaint = Paint()
      ..color = isDark
          ? DesignTokens.black.withAlpha(60)
          : DesignTokens.black.withAlpha(18)
      ..style = PaintingStyle.fill;

    // Rounded corner clip border
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(40),
    );
    canvas.drawRRect(rrect, borderPaint);

    // Status bar dark strip + notch
    const notchW = 110.0;
    const notchH = 6.0;
    const notchTop = 10.0;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, notchTop + notchH + 6),
      shadowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH((width - notchW) / 2, notchTop, notchW, notchH * 2),
        const Radius.circular(notchH),
      ),
      notchPaint,
    );

    // Home indicator
    const homeBarW = 100.0;
    const homeBarH = 4.0;
    const homeBarBottomOffset = 8.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (width - homeBarW) / 2,
          height - homeBarBottomOffset - homeBarH,
          homeBarW,
          homeBarH,
        ),
        const Radius.circular(homeBarH / 2),
      ),
      homeBarPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/// Tablet chrome overlay: camera dot at top, rounded corners, thin border.
class _TabletOverlay extends StatelessWidget {
  const _TabletOverlay({
    required this.width,
    required this.height,
    required this.child,
    this.isDark = true,
  });
  final double width;
  final double height;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox.expand(child: child),
          ),
          CustomPaint(
            size: Size(width, height),
            painter: _TabletChromePainter(
              width: width,
              height: height,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletChromePainter extends CustomPainter {
  _TabletChromePainter({
    required this.width,
    required this.height,
    this.isDark = true,
  });
  final double width;
  final double height;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = isDark ? DesignTokens.darkOutline : DesignTokens.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final cameraPaint = Paint()
      ..color = isDark ? DesignTokens.darkSurface : DesignTokens.textSecondary;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(16),
      ),
      borderPaint,
    );
    // Camera dot
    canvas.drawCircle(Offset(width / 2, 14), 5, cameraPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/// Browser chrome overlay: opaque top bar with dots + URL, content area is below.
/// Content is rendered at height - chromeH to leave room for the chrome bar.
class _BrowserOverlay extends StatelessWidget {
  const _BrowserOverlay({
    required this.width,
    required this.height,
    required this.child,
    this.isDark = true,
  });
  final double width;
  final double height;
  final Widget child;
  final bool isDark;

  static const double _chromeH = 44.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // Browser chrome bar (opaque)
            _BrowserChromeBar(width: width, height: _chromeH, isDark: isDark),
            // Page content fills the rest
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _BrowserChromeBar extends StatelessWidget {
  const _BrowserChromeBar({
    required this.width,
    required this.height,
    this.isDark = true,
  });
  final double width;
  final double height;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: isDark ? DesignTokens.darkSurface : DesignTokens.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _dot(DesignTokens.error),
          const SizedBox(width: 5),
          _dot(DesignTokens.warning),
          const SizedBox(width: 5),
          _dot(DesignTokens.success),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: isDark
                    ? DesignTokens.black.withValues(alpha: 0.26)
                    : DesignTokens.black.withAlpha(15),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                'orignagta.ca',
                style: TextStyle(
                  color: isDark
                      ? DesignTokens.white.withValues(alpha: 0.54)
                      : DesignTokens.black.withValues(alpha: 0.45),
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ============================================================================
// CHECKERBOARD CANVAS BACKGROUND
// ============================================================================

// ============================================================================
// SINGLE-VIEWPORT HELPERS
// ============================================================================

/// Wraps [child] in a mobile phone frame (390×844).
/// Use with `@Preview(size: Size(390, 844))`.
Widget previewMobile({
  required Widget child,
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) {
  return _singleViewport(
    bp: PreviewBreakpoint.mobile,
    child: child,
    theme: theme,
    locale: locale,
  );
}

/// Wraps [child] in a tablet frame (768×1024).
/// Use with `@Preview(size: Size(768, 1024))`.
Widget previewTablet({
  required Widget child,
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) {
  return _singleViewport(
    bp: PreviewBreakpoint.tablet,
    child: child,
    theme: theme,
    locale: locale,
  );
}

/// Wraps [child] in a browser frame at desktop size (1280×800).
/// Use with `@Preview(size: Size(1280, 800))`.
Widget previewDesktop({
  required Widget child,
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) {
  return _singleViewport(
    bp: PreviewBreakpoint.desktop,
    child: child,
    theme: theme,
    locale: locale,
  );
}

/// Wraps [child] in a browser frame at web size (1440×900).
/// Use with `@Preview(size: Size(1440, 900))`.
Widget previewWeb({
  required Widget child,
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) {
  return _singleViewport(
    bp: PreviewBreakpoint.web,
    child: child,
    theme: theme,
    locale: locale,
  );
}

Widget _singleViewport({
  required PreviewBreakpoint bp,
  required Widget child,
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) {
  final effectiveTheme = theme ?? previewDarkTheme;
  final isBrowser = _frameTypeOf(bp) == _FrameType.browser;
  // Browser: content area is below the 44px chrome bar
  final contentH = isBrowser ? bp.height - _BrowserOverlay._chromeH : bp.height;

  final content = Theme(
    data: effectiveTheme,
    child: MediaQuery(
      data: MediaQueryData(size: Size(bp.width, contentH)),
      child: Scaffold(
        backgroundColor: effectiveTheme.scaffoldBackgroundColor,
        body: child,
      ),
    ),
  );

  return _localizationShell(
    locale: locale,
    theme: effectiveTheme,
    size: Size(bp.width, bp.height),
    child: _DeviceFrameOverlay(
      breakpoint: bp,
      isDark: effectiveTheme.brightness == Brightness.dark,
      child: content,
    ),
  );
}

// ============================================================================
// ALL-VIEWPORTS HELPER (horizontal row — 4 frames side by side)
// ============================================================================

/// Shows a screen across all breakpoints side by side, each with device chrome.

/// Builds a device-framed widget for use in the horizontal row view.
// ============================================================================
// WRAPPERS (legacy + grid)
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
  Widget content = Padding(padding: padding, child: child);

  if (breakpoint != null) {
    content = Center(
      child: Container(
        width: breakpoint.width,
        height: breakpoint.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: DesignTokens.textSecondary.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: DesignTokens.black.withValues(alpha: 0.26),
            ),
          ],
        ),
        child: ClipRect(
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(breakpoint.width, breakpoint.height),
            ),
            child: Scaffold(
              backgroundColor: background ?? DesignTokens.darkBackground,
              body: content,
            ),
          ),
        ),
      ),
    );
  } else {
    content = Scaffold(
      backgroundColor: background ?? DesignTokens.darkBackground,
      body: Center(child: content),
    );
  }

  return _localizationShell(locale: locale, theme: theme, child: content);
}

/// Preview wrapper for a row/grid of widget variants (no breakpoint sizing).
Widget previewGrid({
  required List<Widget> children,
  ThemeData? theme,
  Color? background,
  Locale locale = const Locale('en'),
}) {
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
// INTERNALS
// ============================================================================

Widget _localizationShell({
  required Widget child,
  ThemeData? theme,
  Locale locale = const Locale('en'),
  Size? size,
}) {
  Widget home = child;
  if (size != null) {
    home = SizedBox(width: size.width, height: size.height, child: child);
  }

  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('fr'), Locale('es')],
    path: 'packages/origna_gta/assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: locale,
    useOnlyLangCode: true,
    child: Builder(
      builder: (context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme ?? previewDarkTheme,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: home,
      ),
    ),
  );
}

/// No-op UserRepository — prevents backend calls in previews.
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
  Stream<List<Address>> watchAddresses(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) => Stream.value([]);

  @override
  Stream<SellerAccountStatus> watchSellerAccountStatus(String userId) =>
      Stream.value(
        const SellerAccountStatus(isSeller: false, chargesEnabled: false),
      );
}

// ============================================================================
// RESPONSIVE PREVIEW MULTI-PREVIEW
// ============================================================================

/// Custom MultiPreview that generates Mobile, Tablet, and Desktop previews.
/// Use this annotation on a Widget-returning function to automatically generate
/// three preview sizes (Mobile Dark, Tablet Dark, Desktop Dark).
///
/// Example:
/// ```dart
/// @ResponsivePreview()
/// Widget previewMyWidget() => const MyWidget();
/// ```
final class ResponsivePreview extends MultiPreview {
  const ResponsivePreview();

  @override
  List<Preview> get previews => const [
    Preview(
      name: 'Mobile Dark',
      size: Size(390, 844),
      brightness: Brightness.dark,
    ),
    Preview(
      name: 'Tablet Dark',
      size: Size(768, 1024),
      brightness: Brightness.dark,
    ),
    Preview(
      name: 'Desktop Dark',
      size: Size(1280, 800),
      brightness: Brightness.dark,
    ),
  ];
}
