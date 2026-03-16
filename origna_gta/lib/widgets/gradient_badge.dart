import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';

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
    this.textColor = Colors.white,
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
