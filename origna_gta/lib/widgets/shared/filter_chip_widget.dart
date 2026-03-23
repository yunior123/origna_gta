import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String semanticLabel;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.semanticLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        label: semanticLabel,
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: DesignTokens.durationFast,
            padding: padding,
            decoration: BoxDecoration(
              color: isSelected ? DesignTokens.primary : DesignTokens.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? DesignTokens.primary
                    : DesignTokens.outlineVariant.withValues(alpha: 0.5),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: DesignTokens.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? DesignTokens.white
                    : DesignTokens.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
