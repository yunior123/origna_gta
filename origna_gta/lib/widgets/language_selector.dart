import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/preview_helpers.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactLanguageButton();
    }
    return _LanguageDropdown();
  }
}

class _CompactLanguageButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCode = context.locale.languageCode;

    return Semantics(
      label: 'language.select_language'.tr(),
      button: true,
      child: Tooltip(
        message: 'language.select_language'.tr(),
        child: IconButton(
          tooltip: 'language.select_language'.tr(),
          onPressed: () {
            final next = _nextLanguage(currentCode);
            context.setLocale(Locale(next));
            _persistLang(ref, next);
          },
          icon: Text(
            currentCode.toUpperCase(),
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

  String _nextLanguage(String current) {
    final order = [
      LanguageValues.english,
      LanguageValues.french,
      LanguageValues.spanish,
    ];
    final idx = order.indexOf(current);
    return order[(idx + 1) % order.length];
  }
}

class _LanguageDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = context.locale;

    return Semantics(
      label: 'language.select_language'.tr(),
      child: DropdownButton<Locale>(
        value: currentLocale,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.language, color: DesignTokens.primary),
        items: [
          DropdownMenuItem(
            value: const Locale(LanguageValues.english),
            child: Text('language.english'.tr()),
          ),
          DropdownMenuItem(
            value: const Locale(LanguageValues.french),
            child: Text('language.french'.tr()),
          ),
          DropdownMenuItem(
            value: const Locale(LanguageValues.spanish),
            child: Text('language.spanish'.tr()),
          ),
        ],
        onChanged: (locale) {
          if (locale != null) {
            context.setLocale(locale);
            _persistLang(ref, locale.languageCode);
          }
        },
      ),
    );
  }
}

void _persistLang(WidgetRef ref, String langCode) {
  final userId = ref.read(userIdProvider);
  if (userId == null) return;
  final lang = LanguageValues.resolve(langCode);
  ref
      .read(userRepositoryProvider)
      .updatePreferredLanguage(userId, lang)
      .catchError((_) {});
}

// === Widget Previews ===

@Preview(name: 'Language Selector — Variants', group: 'LanguageSelector')
Widget previewLanguageVariants() => previewScope(
  child: previewGrid(
    children: const [
      Padding(padding: EdgeInsets.all(16), child: LanguageSelector()),
      Padding(
        padding: EdgeInsets.all(16),
        child: LanguageSelector(compact: true),
      ),
    ],
  ),
);

@Preview(name: 'Language Selector Light — Variants', group: 'LanguageSelector')
Widget previewLanguageVariantsLight() => previewScope(
  child: previewGrid(
    theme: previewLightTheme,
    children: const [
      Padding(padding: EdgeInsets.all(16), child: LanguageSelector()),
      Padding(
        padding: EdgeInsets.all(16),
        child: LanguageSelector(compact: true),
      ),
    ],
  ),
);
