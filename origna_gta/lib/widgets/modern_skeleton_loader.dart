import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:shimmer/shimmer.dart';

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
