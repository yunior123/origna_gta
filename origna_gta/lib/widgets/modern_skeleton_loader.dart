import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/widget_previews.dart';

class ModernSkeletonLoader extends StatelessWidget {
  final Widget _child;

  const ModernSkeletonLoader._({required Widget child}) : _child = child;

  factory ModernSkeletonLoader.card({double height = 120, double? width}) {
    return ModernSkeletonLoader._(
      child: _ShimmerWrap(
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: DesignTokens.darkSurfaceVariant,
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
        ),
      ),
    );
  }

  factory ModernSkeletonLoader.listTile() {
    return const ModernSkeletonLoader._(child: _ListTileSkeleton());
  }

  factory ModernSkeletonLoader.text({double width = 200, double height = 14}) {
    return ModernSkeletonLoader._(
      child: _ShimmerWrap(
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: DesignTokens.darkSurfaceVariant,
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
        ),
      ),
    );
  }

  /// Theme-aware image placeholder shimmer for [CachedNetworkImage].
  ///
  /// Defaults — light: outlineVariant / surface, dark: darkCard / darkSurfaceVariant.
  /// Supply [baseColor] / [highlightColor] to override the defaults.
  /// Optional [width], [height], and [fillColor] control the inner container.
  factory ModernSkeletonLoader.imagePlaceholder({
    bool isDark = false,
    double? width,
    double? height,
    Color? baseColor,
    Color? highlightColor,
    Color? fillColor,
  }) {
    return ModernSkeletonLoader._(
      child: _ThemedShimmerWrap(
        isDark: isDark,
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: width,
          height: height,
          color:
              fillColor ??
              (isDark ? DesignTokens.darkSurface : DesignTokens.white),
        ),
      ),
    );
  }

  /// Wraps an arbitrary [child] in a theme-aware shimmer effect.
  ///
  /// Use this for complex skeletons (list views, multi-container layouts)
  /// that need more than a simple rectangle.
  /// Supply [baseColor] / [highlightColor] to override the defaults.
  factory ModernSkeletonLoader.wrap({
    required Widget child,
    bool isDark = false,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return ModernSkeletonLoader._(
      child: _ThemedShimmerWrap(
        isDark: isDark,
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _child;
}

class _ShimmerWrap extends StatelessWidget {
  final Widget child;

  const _ShimmerWrap({required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: DesignTokens.darkSurfaceVariant,
      highlightColor: DesignTokens.darkCard,
      child: child,
    );
  }
}

/// Theme-aware shimmer wrapper that picks colours based on [isDark].
///
/// When [baseColor] or [highlightColor] are provided they take precedence
/// over the automatic dark/light defaults.
class _ThemedShimmerWrap extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color? baseColor;
  final Color? highlightColor;

  const _ThemedShimmerWrap({
    required this.child,
    required this.isDark,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:
          baseColor ??
          (isDark ? DesignTokens.darkCard : DesignTokens.outlineVariant),
      highlightColor:
          highlightColor ??
          (isDark ? DesignTokens.darkSurfaceVariant : DesignTokens.surface),
      child: child,
    );
  }
}

class _ListTileSkeleton extends StatelessWidget {
  const _ListTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: DesignTokens.darkSurfaceVariant,
      highlightColor: DesignTokens.darkCard,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: DesignTokens.darkSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: DesignTokens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: DesignTokens.darkSurfaceVariant,
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing8),
                Container(
                  height: 12,
                  width: 140,
                  decoration: BoxDecoration(
                    color: DesignTokens.darkSurfaceVariant,
                    borderRadius: BorderRadius.circular(DesignTokens.radius8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// === Widget Previews ===

// ═══ Widget Previews ═══

@Preview(name: 'Skeleton Card', group: 'ModernSkeletonLoader')
Widget previewSkeletonCard() =>
    previewWrapper(child: ModernSkeletonLoader.card(height: 120));

@Preview(name: 'Skeleton List Tile', group: 'ModernSkeletonLoader')
Widget previewSkeletonListTile() =>
    previewWrapper(child: ModernSkeletonLoader.listTile());

@Preview(name: 'Skeleton Text', group: 'ModernSkeletonLoader')
Widget previewSkeletonText() => previewWrapper(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ModernSkeletonLoader.text(width: 200, height: 14),
      const SizedBox(height: 8),
      ModernSkeletonLoader.text(width: 160, height: 14),
      const SizedBox(height: 8),
      ModernSkeletonLoader.text(width: 240, height: 14),
    ],
  ),
);

@Preview(name: 'Skeleton Image Placeholder', group: 'ModernSkeletonLoader')
Widget previewSkeletonImagePlaceholder() => previewWrapper(
  child: SizedBox(
    width: 120,
    height: 120,
    child: ModernSkeletonLoader.imagePlaceholder(width: 120, height: 120),
  ),
);

@Preview(name: 'Skeleton Wrap (complex)', group: 'ModernSkeletonLoader')
Widget previewSkeletonWrap() => previewWrapper(
  child: ModernSkeletonLoader.wrap(
    isDark: true,
    child: Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ModernSkeletonLoader.card(width: 80, height: 80),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernSkeletonLoader.text(width: 140, height: 14),
                const SizedBox(height: 8),
                ModernSkeletonLoader.text(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

@Preview(name: 'Skeleton Variants', group: 'ModernSkeletonLoader')
Widget previewSkeletonVariants() => previewGrid(
  children: [
    ModernSkeletonLoader.card(height: 80),
    ModernSkeletonLoader.listTile(),
    ModernSkeletonLoader.text(width: 180, height: 16),
  ],
);

@Preview(name: 'Skeleton Light — Card', group: 'ModernSkeletonLoader')
Widget previewSkeletonCardLight() => previewWrapper(
  theme: previewLightTheme,
  background: DesignTokens.surface,
  child: ModernSkeletonLoader.card(height: 120),
);
