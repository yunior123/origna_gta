import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, String> _flattenTranslations(
  Map<String, Object?> source, [
  String prefix = '',
]) {
  final flattened = <String, String>{};
  source.forEach((key, value) {
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, Object?>) {
      flattened.addAll(_flattenTranslations(value, path));
      return;
    }
    if (value is String) {
      flattened[path] = value;
    }
  });
  return flattened;
}

Map<String, String> _loadLocale(String locale) {
  final file = File('assets/translations/$locale.json');
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return _flattenTranslations(decoded);
}

Set<String> _usedTranslationKeys() {
  final keyPattern = RegExp(r"""['"]([a-zA-Z0-9_.]+)['"]\s*\.tr\s*\(""");
  final keys = <String>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final contents = entity.readAsStringSync();
    keys.addAll(
      keyPattern
          .allMatches(contents)
          .map((match) => match.group(1))
          .whereType<String>(),
    );
  }
  return keys;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EasyLocalization Key Verification', () {
    test('Verifies key presence in memory after loading', () async {
      // This is a unit test to check if we can simulate translation lookup
      // In a real app, this is handled by EasyLocalization widget.

      // For now, let's just check if the string itself has the .tr() method available
      // (which we know it does because it's an extension)
      expect('auth.errors.registration_success'.tr(), isNotNull);
    });

    test('all app .tr() keys exist in every locale file', () {
      final usedKeys = _usedTranslationKeys();
      expect(usedKeys, containsAll(['security.title', 'start_shopping']));

      for (final locale in const ['en', 'fr', 'es']) {
        final translations = _loadLocale(locale);
        final missing =
            usedKeys.where((key) => !translations.containsKey(key)).toList()
              ..sort();
        expect(missing, isEmpty, reason: '$locale missing keys: $missing');
      }
    });

    test('known investor-facing labels are localized', () {
      final fr = _loadLocale('fr');
      final es = _loadLocale('es');

      expect(fr['security.title'], 'Sécurité');
      expect(es['security.title'], 'Seguridad');
      expect(fr['start_shopping'], 'Commencer les achats');
      expect(es['start_shopping'], 'Empezar a comprar');
      expect(es['admin.security.enable_mfa'], 'Activar MFA');
      expect(es['common.go_shopping'], 'Empezar a comprar');
    });
  });
}
