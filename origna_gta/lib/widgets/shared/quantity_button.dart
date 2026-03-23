import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// Shared quantity +/- button used on product detail and cart item screens.
///
/// [isDark] controls the active icon color in dark mode.
/// [useHaptic] enables haptic feedback on tap (default: false).
class QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final bool isDark;
  final bool useHaptic;

  const QuantityButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.isDark = false,
    this.useHaptic = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final activeColor = isDark
        ? DesignTokens.white.withValues(alpha: 0.7)
        : DesignTokens.primary;

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: !isDisabled,
      child: Material(
        color: DesignTokens.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radius8),
          onTap: isDisabled
              ? null
              : () {
                  if (useHaptic) HapticFeedback.selectionClick();
                  onPressed!();
                },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: isDisabled ? DesignTokens.textDisabled : activeColor,
            ),
          ),
        ),
      ),
    );
  }
}
