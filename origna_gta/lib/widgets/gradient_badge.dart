import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:flutter/widget_previews.dart';

class GradientBadge extends StatelessWidget {
  final String label;
  final LinearGradient? gradient;
  final Color textColor;
  final double fontSize;
  final EdgeInsets padding;

  const GradientBadge({
    super.key,
    required this.label,
    this.gradient,
    this.textColor = DesignTokens.white,
    this.fontSize = 11.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? DesignTokens.primaryGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radius32),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}

// === Widget Previews ===

// ═══ Widget Previews ═══

@Preview(name: 'Gradient Badge — Variants', group: 'GradientBadge')
Widget previewGradientBadgeVariants() => previewGrid(
  children: [
    const GradientBadge(label: 'SALE'),
    const GradientBadge(
      label: 'HOT',
      gradient: LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
    ),
    const GradientBadge(
      label: 'NEW',
      gradient: LinearGradient(
        colors: [DesignTokens.success, DesignTokens.info],
      ),
    ),
    GradientBadge(
      label: 'PREMIUM',
      gradient: LinearGradient(
        colors: [DesignTokens.warning, DesignTokens.tertiary],
      ),
    ),
  ],
);

@Preview(name: 'Gradient Badge — Sizes', group: 'GradientBadge')
Widget previewGradientBadgeSizes() => previewGrid(
  children: [
    const GradientBadge(
      label: 'Small',
      fontSize: 9,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    ),
    const GradientBadge(label: 'Default', fontSize: 11),
    const GradientBadge(
      label: 'Large',
      fontSize: 13,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    ),
  ],
);

@Preview(name: 'Gradient Badge — Single', group: 'GradientBadge')
Widget previewGradientBadgeSingle() => previewWrapper(
  child: const Center(child: GradientBadge(label: '50% OFF')),
);

@Preview(name: 'Gradient Badge Light — Variants', group: 'GradientBadge')
Widget previewGradientBadgeVariantsLight() => previewGrid(
  theme: previewLightTheme,
  children: [
    const GradientBadge(label: 'SALE', textColor: DesignTokens.white),
    const GradientBadge(
      label: 'NEW',
      gradient: LinearGradient(
        colors: [DesignTokens.success, DesignTokens.info],
      ),
      textColor: DesignTokens.white,
    ),
  ],
);
