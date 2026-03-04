/// Previews for LanguageSelector widget.
///
/// NOTE: LanguageSelector internals use easy_localization (context.locale)
/// and Riverpod (userIdProvider / userRepositoryProvider).
/// The widget previewer scaffold does not include EasyLocalization in the
/// widget tree, so context.locale would throw at runtime.
/// These previews render static visual representations of each variant
/// that faithfully reflect the real widget's appearance.
library;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import '_preview_theme.dart';

// ── Compact variant (flag/icon button) ────────────────────────────────────

@Preview(
  name: 'Compact — shows FR (EN active)',
  group: 'LanguageSelector',
  size: Size(80, 80),
)
Widget previewLanguageSelectorCompactEn() => previewWrapper(
      child: Tooltip(
        message: 'language.select_language', // .tr() → key in preview mode
        child: IconButton(
          tooltip: 'language.select_language',
          onPressed: null,
          icon: const Text(
            'FR',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: DesignTokens.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );

@Preview(
  name: 'Compact — shows EN (FR active)',
  group: 'LanguageSelector',
  size: Size(80, 80),
)
Widget previewLanguageSelectorCompactFr() => previewWrapper(
      child: Tooltip(
        message: 'language.select_language',
        child: IconButton(
          tooltip: 'language.select_language',
          onPressed: null,
          icon: const Text(
            'EN',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: DesignTokens.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );

// ── Full dropdown variant ─────────────────────────────────────────────────

@Preview(
  name: 'Dropdown — dark',
  group: 'LanguageSelector',
  size: Size(200, 80),
)
Widget previewLanguageSelectorDropdownDark() => previewWrapper(
      child: DropdownButton<String>(
        value: 'en',
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.language, color: DesignTokens.primary),
        items: const [
          DropdownMenuItem(value: 'en', child: Text('English')),
          DropdownMenuItem(value: 'fr', child: Text('Français')),
        ],
        onChanged: null, // static preview — no state
      ),
    );

@Preview(
  name: 'Dropdown — light',
  group: 'LanguageSelector',
  brightness: Brightness.light,
  size: Size(200, 80),
)
Widget previewLanguageSelectorDropdownLight() => previewWrapper(
      theme: previewLightTheme,
      background: DesignTokens.surface,
      child: DropdownButton<String>(
        value: 'fr',
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.language, color: DesignTokens.primary),
        items: const [
          DropdownMenuItem(value: 'en', child: Text('English')),
          DropdownMenuItem(value: 'fr', child: Text('Français')),
        ],
        onChanged: null,
      ),
    );
