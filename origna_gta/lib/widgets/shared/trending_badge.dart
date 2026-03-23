import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// Shared trending badge used by product cards.
/// HOT badge (score >= 50) uses fire gradient; RISING badge uses teal gradient.
class TrendingBadge extends StatelessWidget {
  final int score;
  final bool isCompact;

  /// Optional overrides for the hot-state gradient colors.
  final List<Color>? hotColors;

  /// Optional overrides for the rising-state gradient colors.
  final List<Color>? risingColors;

  const TrendingBadge({
    super.key,
    required this.score,
    required this.isCompact,
    this.hotColors,
    this.risingColors,
  });

  @override
  Widget build(BuildContext context) {
    final isHot = score >= 50;
    final label = isHot
        ? 'product.trending_hot'.tr()
        : 'product.trending_rising'.tr();
    final colors = isHot
        ? (hotColors ?? [DesignTokens.hotStart, DesignTokens.hotEnd])
        : (risingColors ??
              [DesignTokens.trendingStart, DesignTokens.trendingEnd]);
    final glowColor = colors.first;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 5 : 7,
        vertical: isCompact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isCompact ? 9 : 10,
          fontWeight: FontWeight.w800,
          color: DesignTokens.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
