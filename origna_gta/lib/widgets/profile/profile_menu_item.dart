import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

/// A styled menu item row used in the profile screen.
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String? semanticLabel;
  final String title;
  final String? subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    this.semanticLabel,
    required this.title,
    this.subtitle,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? DesignTokens.darkSurfaceVariant.withValues(alpha: 0.5)
            : DesignTokens.white,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: isDark
              ? DesignTokens.darkOutline
              : DesignTokens.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label:
            semanticLabel ?? 'menu-${title.toLowerCase().replaceAll(' ', '-')}',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          behavior: HitTestBehavior.opaque,
          child: Semantics(
            container: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DesignTokens.primary.withValues(alpha: 0.15),
                          DesignTokens.secondary.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(DesignTokens.radius8),
                    ),
                    child: Icon(icon, color: DesignTokens.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? DesignTokens.textOnDark
                                : DesignTokens.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: DesignTokens.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isLoading)
                    const ModernLoadingIndicator.small()
                  else
                    Icon(
                      Icons.chevron_right,
                      color: DesignTokens.textDisabled,
                      size: 20,
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
