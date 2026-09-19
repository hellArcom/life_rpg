import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_rpg_dev/core/translations.dart';

void main() {
  group('Translations coverage', () {
    late Map<String, String> fr;
    late Map<String, String> en;
    late Set<String> keys;

    setUpAll(() {
      fr = Translations.fr;
      en = Translations.en;
      final src = File('lib/core/translations.dart').readAsStringSync();
      // Collect every literal key passed to get('...')
      final re = RegExp(r"""get\(\s*['"]([^'"]+)['"]\s*\)""");
      // Exclude runtime-interpolated keys like get('badge_title_$id')
      keys = re.allMatches(src)
          .map((m) => m.group(1)!)
          .where((k) => !k.contains('\$'))
          .toSet();
    });

    test('fr and en have identical key sets', () {
      final frKeys = fr.keys.toSet();
      final enKeys = en.keys.toSet();
      expect(frKeys.difference(enKeys), isEmpty,
          reason: 'keys missing in en: ${frKeys.difference(enKeys)}');
      expect(enKeys.difference(frKeys), isEmpty,
          reason: 'keys missing in fr: ${enKeys.difference(frKeys)}');
    });

    test('every getter key exists in fr and en', () {
      final missingFr = <String>[];
      final missingEn = <String>[];
      for (final k in keys) {
        if (!fr.containsKey(k)) missingFr.add(k);
        if (!en.containsKey(k)) missingEn.add(k);
      }
      expect(missingFr, isEmpty, reason: 'missing in fr: $missingFr');
      expect(missingEn, isEmpty, reason: 'missing in en: $missingEn');
    });

    test('no empty translation values in fr/en', () {
      expect(fr.values.where((v) => v.trim().isEmpty), isEmpty,
          reason: 'empty fr values');
      expect(en.values.where((v) => v.trim().isEmpty), isEmpty,
          reason: 'empty en values');
    });

    test('Translations.get falls back to en then key (no crash)', () {
      expect(Translations(Translations.en).get('coins'), isNotEmpty);
      expect(Translations(Translations.en).get('this_key_does_not_exist'),
          equals('this_key_does_not_exist'));
    });

    test('fr and en are not identical (real translations)', () {
      var differ = 0;
      for (final k in fr.keys) {
        if (fr[k] != en[k]) differ++;
      }
      // At least a substantial number of keys should actually be localized.
      expect(differ, greaterThan(100),
          reason: 'fr and en are suspiciously similar ($differ diffs)');
    });
  });
}
