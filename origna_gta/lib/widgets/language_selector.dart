import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/utils/design_tokens.dart';

/// Language selector widget for Quebec Bill 96 compliance.
/// Allows users to switch between English and French.
/// Can be placed in profile/settings or app bar.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, this.compact = false});

  /// If true, shows only a flag/icon button instead of full dropdown
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactLanguageButton();
    }
    return _LanguageDropdown();
  }
}

class _CompactLanguageButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;
    final isEn = currentLocale.languageCode == 'en';

    return Semantics(
      label: 'language.select_language'.tr(),
      button: true,
      child: Tooltip(
        message: 'language.select_language'.tr(),
        child: IconButton(
          onPressed: () {
            // Toggle between EN and FR
            final newLocale = isEn ? const Locale('fr') : const Locale('en');
            context.setLocale(newLocale);
          },
          icon: Text(
            isEn ? 'FR' : 'EN',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: DesignTokens.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;

    return Semantics(
      label: 'language.select_language'.tr(),
      child: DropdownButton<Locale>(
        value: currentLocale,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.language, color: DesignTokens.primary),
        items: const [
          DropdownMenuItem(
            value: Locale('en'),
            child: Text('English'),
          ),
          DropdownMenuItem(
            value: Locale('fr'),
            child: Text('Français'),
          ),
        ],
        onChanged: (locale) {
          if (locale != null) {
            context.setLocale(locale);
          }
        },
      ),
    );
  }
}
