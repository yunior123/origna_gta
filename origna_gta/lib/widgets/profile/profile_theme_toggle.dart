import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// A theme toggle row with a 3-segment pill (Light | System | Dark).
///
/// Requires [themePillBuilder] to render each pill segment, since
/// `_ThemePill` is defined in the profile_screen part file.
class ProfileThemeToggle extends StatelessWidget {
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeChange;
  final Widget Function({
    required IconData icon,
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  })
  themePillBuilder;

  const ProfileThemeToggle({
    super.key,
    required this.themeMode,
    required this.onThemeChange,
    required this.themePillBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const Key('profile_theme_button'),
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
        label: 'menu-appearance',
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
                child: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : themeMode == ThemeMode.light
                      ? Icons.light_mode_rounded
                      : Icons.brightness_auto_rounded,
                  color: DesignTokens.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.theme'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark
                            ? DesignTokens.textOnDark
                            : DesignTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'profile.theme_desc'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 3-segment pill toggle: Light | System | Dark
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? DesignTokens.darkSurface
                      : DesignTokens.surfaceVariant,
                  borderRadius: BorderRadius.circular(DesignTokens.radius20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    themePillBuilder(
                      icon: Icons.light_mode_rounded,
                      label: 'profile.theme_light'.tr(),
                      selected: themeMode == ThemeMode.light,
                      isDark: isDark,
                      onTap: () => onThemeChange(ThemeMode.light),
                    ),
                    themePillBuilder(
                      icon: Icons.brightness_auto_rounded,
                      label: 'profile.theme_system'.tr(),
                      selected: themeMode == ThemeMode.system,
                      isDark: isDark,
                      onTap: () => onThemeChange(ThemeMode.system),
                    ),
                    themePillBuilder(
                      icon: Icons.dark_mode_rounded,
                      label: 'profile.theme_dark'.tr(),
                      selected: themeMode == ThemeMode.dark,
                      isDark: isDark,
                      onTap: () => onThemeChange(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
