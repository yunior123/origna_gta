/// Responsive layout utilities for OrignaGta
/// Provides breakpoints and helpers for responsive design across 320px to 1024px+
library;

import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  // Standard breakpoints (matching common device sizes)
  static const double mobile = 320; // 320px (small phones)
  static const double mobilePlus = 480; // 480px (medium phones)
  static const double tablet = 768; // 768px (tablets, large phones)
  static const double desktop = 1024; // 1024px+ (desktops, large tablets)

  /// Get font scale factor for responsive text
  static double getFontScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobilePlus) return 0.9; // 10% smaller on tiny phones
    if (width < tablet) return 1.0; // Normal on phones
    if (width < desktop) return 1.1; // 10% larger on tablets
    return 1.2; // 20% larger on desktop
  }

  /// Get grid column count based on screen size
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 340) return 1; // Single column only on very small phones
    if (width < tablet) return 2; // 2 columns on most phones (iPhone SE -> Max)
    if (width < desktop) return 3; // 3 columns on tablets
    return 4; // 4+ columns on desktop
  }

  /// Get safe padding for edges (avoids notches, safe areas)
  static EdgeInsets getSafePadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    // Reduce padding on small devices
    if (width < mobilePlus) {
      return EdgeInsets.fromLTRB(mediaQuery.padding.left + 8, mediaQuery.padding.top + 8, mediaQuery.padding.right + 8, mediaQuery.padding.bottom + 8);
    }

    return EdgeInsets.fromLTRB(mediaQuery.padding.left + 16, mediaQuery.padding.top + 16, mediaQuery.padding.right + 16, mediaQuery.padding.bottom + 16);
  }

  /// Get spacing value based on screen size
  static double getSpacing(BuildContext context, SpacingSize size) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobilePlus) {
      // Tighter spacing on small phones
      return _getTinySpacing(size);
    }
    if (width < tablet) {
      // Normal spacing on medium phones
      return _getNormalSpacing(size);
    }
    if (width < desktop) {
      // Loose spacing on tablets
      return _getLooseSpacing(size);
    }
    // Extra loose spacing on desktop
    return _getExtraLooseSpacing(size);
  }

  /// Get responsive value based on screen width
  static T getValue<T>({required BuildContext context, required T mobile, required T mobilePlus, required T tablet, required T desktop}) {
    final width = MediaQuery.of(context).size.width;

    if (width < ResponsiveBreakpoints.mobilePlus) return mobile;
    if (width < ResponsiveBreakpoints.tablet) return mobilePlus;
    if (width < ResponsiveBreakpoints.desktop) return tablet;
    return desktop;
  }

  static double _getExtraLooseSpacing(SpacingSize size) {
    switch (size) {
      case SpacingSize.xs:
        return 12;
      case SpacingSize.sm:
        return 16;
      case SpacingSize.md:
        return 20;
      case SpacingSize.lg:
        return 24;
      case SpacingSize.xl:
        return 32;
    }
  }

  static double _getLooseSpacing(SpacingSize size) {
    switch (size) {
      case SpacingSize.xs:
        return 8;
      case SpacingSize.sm:
        return 12;
      case SpacingSize.md:
        return 16;
      case SpacingSize.lg:
        return 20;
      case SpacingSize.xl:
        return 28;
    }
  }

  static double _getNormalSpacing(SpacingSize size) {
    switch (size) {
      case SpacingSize.xs:
        return 6;
      case SpacingSize.sm:
        return 8;
      case SpacingSize.md:
        return 12;
      case SpacingSize.lg:
        return 16;
      case SpacingSize.xl:
        return 24;
    }
  }

  static double _getTinySpacing(SpacingSize size) {
    switch (size) {
      case SpacingSize.xs:
        return 4;
      case SpacingSize.sm:
        return 6;
      case SpacingSize.md:
        return 8;
      case SpacingSize.lg:
        return 12;
      case SpacingSize.xl:
        return 16;
    }
  }
}

/// No-collapse responsive container
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  const ResponsiveContainer({super.key, required this.child, this.maxWidth = 1200, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final constraints = BoxConstraints(maxWidth: width < maxWidth ? width : maxWidth);

    return Center(
      child: Padding(
        padding: padding,
        child: ConstrainedBox(constraints: constraints, child: child),
      ),
    );
  }
}

/// Responsive grid view
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  final double spacing;

  const ResponsiveGridView({super.key, required this.children, this.padding = const EdgeInsets.all(16), this.spacing = 12});

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveBreakpoints.getGridColumns(context);

    return Padding(
      padding: padding,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: spacing, crossAxisSpacing: spacing),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

/// Responsive layout builders
class ResponsiveLayout extends StatelessWidget {
  final Widget mobilePlus; // 320px+
  final Widget tablet; // 768px+
  final Widget desktop; // 1024px+

  const ResponsiveLayout({super.key, required this.mobilePlus, required this.tablet, required this.desktop});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < ResponsiveBreakpoints.tablet) {
      return mobilePlus;
    }
    if (width < ResponsiveBreakpoints.desktop) {
      return tablet;
    }
    return desktop;
  }
}

/// Responsive text styles
class ResponsiveText {
  static TextStyle body(BuildContext context) {
    final scale = ResponsiveBreakpoints.getFontScale(context);
    return TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.normal, height: 1.5);
  }

  static TextStyle caption(BuildContext context) {
    final scale = ResponsiveBreakpoints.getFontScale(context);
    return TextStyle(fontSize: 12 * scale, fontWeight: FontWeight.normal, height: 1.4);
  }

  static TextStyle heading1(BuildContext context) {
    final scale = ResponsiveBreakpoints.getFontScale(context);
    return TextStyle(fontSize: 28 * scale, fontWeight: FontWeight.bold, height: 1.2);
  }

  static TextStyle heading2(BuildContext context) {
    final scale = ResponsiveBreakpoints.getFontScale(context);
    return TextStyle(fontSize: 24 * scale, fontWeight: FontWeight.bold, height: 1.3);
  }

  static TextStyle heading3(BuildContext context) {
    final scale = ResponsiveBreakpoints.getFontScale(context);
    return TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.w600, height: 1.4);
  }
}

enum SpacingSize {
  xs, // Extra small (4-12px)
  sm, // Small (6-16px)
  md, // Medium (8-20px)
  lg, // Large (12-24px)
  xl, // Extra large (16-32px)
}
