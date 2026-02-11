/// Modern loading indicator with glassmorphism aesthetic
/// Replaces raw CircularProgressIndicator throughout the app
library;

import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// A styled loading indicator consistent with the OrignaGTA 2100 design system.
///
/// Use instead of raw [CircularProgressIndicator] for consistent loading UX.
///
/// Variants:
/// - [ModernLoadingIndicator] — inline spinner (e.g. inside buttons, fields)
/// - [ModernLoadingIndicator.fullScreen] — centered overlay with optional message
/// - [ModernLoadingIndicator.small] — compact 16×16 spinner for tight spaces
class ModernLoadingIndicator extends StatelessWidget {
  /// Diameter of the spinner.
  final double size;

  /// Stroke width.
  final double strokeWidth;

  /// Primary color of the spinner arc.
  final Color? color;

  /// Optional label shown below the spinner (only in non-inline mode).
  final String? message;

  /// Whether to center the indicator and fill available space.
  final bool centered;

  /// Padding around the indicator.
  final EdgeInsets padding;

  const ModernLoadingIndicator({
    super.key,
    this.size = 24,
    this.strokeWidth = 2.5,
    this.color,
    this.message,
    this.centered = true,
    this.padding = EdgeInsets.zero,
  });

  /// Full-screen centered loading indicator with optional message.
  const ModernLoadingIndicator.fullScreen({
    super.key,
    this.message,
    this.color,
  })  : size = 32,
        strokeWidth = 3.0,
        centered = true,
        padding = const EdgeInsets.all(16);

  /// Compact spinner for tight spaces (buttons, badges).
  const ModernLoadingIndicator.small({
    super.key,
    this.color,
  })  : size = 16,
        strokeWidth = 2.0,
        message = null,
        centered = false,
        padding = EdgeInsets.zero;

  @override
  Widget build(BuildContext context) {
    final indicator = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation(
                color ?? DesignTokens.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: TextStyle(
                fontSize: 13,
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (centered) {
      return Center(child: indicator);
    }
    return indicator;
  }
}
