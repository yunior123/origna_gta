import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/previews/_preview_theme.dart';
import 'package:origna_gta/widgets/language_selector.dart';

@Preview(name: 'Language Selector — Variants', group: 'LanguageSelector')
Widget previewLanguageVariants() => ProviderScope(
  overrides: [userIdProvider.overrideWithValue('preview-user'), userRepositoryProvider.overrideWithValue(_MockUserRepository() as dynamic)],
  child: previewGrid(
    children: [
      const Padding(padding: EdgeInsets.all(16.0), child: LanguageSelector()),
      const Padding(padding: EdgeInsets.all(16.0), child: LanguageSelector(compact: true)),
    ],
  ),
);

// Mock repository for preview
class _MockUserRepository {
  Future<void> updatePreferredLanguage(String userId, String lang) async {}
}
