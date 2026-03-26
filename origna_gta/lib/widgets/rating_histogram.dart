import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:flutter/widget_previews.dart';

/// Displays a 5-star rating breakdown as a bar histogram.
///
/// [counts] — list of 5 ints: [count5star, count4star, count3star, count2star, count1star]
/// [total]  — sum of all counts (used to compute bar fill ratio)
class RatingHistogram extends StatelessWidget {
  final List<int> counts;
  final int total;

  const RatingHistogram({
    super.key,
    required this.counts,
    required this.total,
  }) : assert(counts.length == 5, 'counts must have exactly 5 elements');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: List.generate(5, (i) {
        final star = 5 - i;
        final count = counts[i];
        final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$star',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star_rounded, size: 14, color: DesignTokens.warning),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    color: DesignTokens.warning,
                    backgroundColor: isDark
                        ? DesignTokens.darkSurfaceVariant
                        : DesignTokens.outlineVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    color: DesignTokens.textDisabled,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}


// === Widget Previews ===


// ═══ Widget Previews ═══

@Preview(name: 'Rating Histogram — Variants', group: 'RatingHistogram')
Widget previewHistogramVariants() => previewGrid(
  children: [
    RatingHistogram(counts: [45, 12, 5, 2, 1], total: 65),
    RatingHistogram(counts: [100, 50, 20, 10, 5], total: 185),
    RatingHistogram(counts: [0, 0, 0, 0, 0], total: 0),
  ],
);

@Preview(name: 'Rating Histogram Light — Variants', group: 'RatingHistogram')
Widget previewHistogramVariantsLight() => previewGrid(
  theme: previewLightTheme,
  children: [
    RatingHistogram(counts: [45, 12, 5, 2, 1], total: 65),
    RatingHistogram(counts: [100, 50, 20, 10, 5], total: 185),
    RatingHistogram(counts: [0, 0, 0, 0, 0], total: 0),
  ],
);



// ═══ Widget Previews ═══

// ─── Perfect rating (all 5-star) ─────────────────────────────────────────────

@Preview(name: 'Perfect — all 5-star', group: 'RatingHistogram')
Widget previewRatingPerfect() => previewWrapper(
  child: RatingHistogram(
    counts: [120, 0, 0, 0, 0], // [5★, 4★, 3★, 2★, 1★]
    total: 120,
  ),
);

// ─── Mixed rating ─────────────────────────────────────────────────────────────

@Preview(name: 'Mixed — realistic distribution', group: 'RatingHistogram')
Widget previewRatingMixed() => previewWrapper(
  child: RatingHistogram(
    counts: [84, 31, 12, 7, 4], // [5★, 4★, 3★, 2★, 1★]
    total: 138,
  ),
);

// ─── Low rating ───────────────────────────────────────────────────────────────

@Preview(name: 'Low — mostly 1-2 star', group: 'RatingHistogram')
Widget previewRatingLow() => previewWrapper(
  child: RatingHistogram(
    counts: [3, 5, 14, 28, 50], // [5★, 4★, 3★, 2★, 1★]
    total: 100,
  ),
);

// ─── Empty (no reviews yet) ───────────────────────────────────────────────────

@Preview(name: 'Empty — no reviews', group: 'RatingHistogram')
Widget previewRatingEmpty() => previewWrapper(
  child: RatingHistogram(
    counts: [0, 0, 0, 0, 0],
    total: 0,
  ),
);

// ─── Light theme variant ──────────────────────────────────────────────────────

@Preview(name: 'Mixed — light theme', group: 'RatingHistogram', brightness: Brightness.light)
Widget previewRatingMixedLight() => previewWrapper(
  theme: previewLightTheme,
  background: DesignTokens.surface,
  child: RatingHistogram(
    counts: [84, 31, 12, 7, 4],
    total: 138,
  ),
);

// ─── All variants stacked ─────────────────────────────────────────────────────

@Preview(name: 'All variants', group: 'RatingHistogram')
Widget previewRatingAllVariants() => previewGrid(
  children: [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perfect (120 reviews)',
          style: TextStyle(
            color: DesignTokens.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RatingHistogram(counts: [120, 0, 0, 0, 0], total: 120),
      ],
    ),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mixed (138 reviews)',
          style: TextStyle(
            color: DesignTokens.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RatingHistogram(counts: [84, 31, 12, 7, 4], total: 138),
      ],
    ),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Low (100 reviews)',
          style: TextStyle(
            color: DesignTokens.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RatingHistogram(counts: [3, 5, 14, 28, 50], total: 100),
      ],
    ),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No reviews yet',
          style: TextStyle(
            color: DesignTokens.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RatingHistogram(counts: [0, 0, 0, 0, 0], total: 0),
      ],
    ),
  ],
);

