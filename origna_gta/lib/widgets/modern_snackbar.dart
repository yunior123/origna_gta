import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';

class ModernSnackbar {
  ModernSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    final IconData resolvedIcon =
        icon ??
        (isSuccess
            ? Icons.check_circle_outline_rounded
            : isError
            ? Icons.error_outline_rounded
            : Icons.info_outline_rounded);

    final Color iconColor = isSuccess
        ? DesignTokens.success
        : isError
        ? DesignTokens.error
        : DesignTokens.accent;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: DesignTokens.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(DesignTokens.spacing16),
          content: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacing16,
                  vertical: DesignTokens.spacing12,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.darkCard.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(DesignTokens.radius16),
                  boxShadow: DesignTokens.shadowLg,
                  border: Border.all(
                    color: DesignTokens.darkOutline.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(resolvedIcon, color: iconColor, size: 20),
                    const SizedBox(width: DesignTokens.spacing8),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: DesignTokens.textOnDark,
                          fontSize: DesignTokens.fontSizeSm,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }
}
