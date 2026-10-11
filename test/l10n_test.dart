// Altı dil: arayüz metinleri ve dil tercihi. Kodda her metin Türkçe yazılır
// ve `context.t('…')` ile çevrilir; çeviriler lib/l10n/strings/*.dart'ta.
// Bu test: (1) kodda t('…') ile istenen her metnin beş dilde de karşılığı
// var, yer tutucuları aynı; (2) ekranda çevrilmeden kalan Türkçe metin yok;
// (3) dil tercihi cihaz dili / elle seçim / kalıcılık.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_okuma_rehberi/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `t('…')`, `context.t("…")`, `L10n.text(x, '…')` with a literal.
final _tCall = RegExp(
  r'''(?:\.t|\bL10n\.text\([^,]+,)\(?\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")''',
);

/// A literal shown as is: `Text('…')`, `tooltip: '…'`, Semantics labels…
final _shown = RegExp(
  r'''(?:\bText\(\s*|\b(?:tooltip|semanticsLabel|labelText|hintText|helperText|message):\s*|\bSemantics\([^)]*?\blabel:\s*)(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")''',
);

final _placeholder = RegExp(r'\{(\w+)\}');
final _latinWord = RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]{2,}');

Iterable<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

String _unescape(String s) =>
    s.replaceAll(r"\'", "'").replaceAll(r'\"', '"').replaceAll(r'\n', '\n');

void main() {
  test('composed feedback and reading nouns use the selected language', () {
    expect(L10n.text(AppLanguage.en, 'Deneme: 3'), 'Attempts: 3');
    expect(L10n.text(AppLanguage.fr, 'Seviye 2 · Zor'), 'Niveau 2 · Difficile');
    expect(
      L10n.text(AppLanguage.es, 'Buldun! Kalan: 2'),
      '¡Encontrada! Restantes: 2',
    );
    const source =
        'Aşağıdaki "Ezberle" düğmesine bas: her {part} {n} kez okunur, sonra bir sonrakine geçilir.';
    final french = L10n.text(AppLanguage.fr, source, {'part': 'bölüm', 'n': 3});
    expect(french, contains('chaque partie'));
    expect(french, isNot(contains('bölüm')));
  });
  group('çeviri tabloları', () {
    test('aktif dillerde satırlar dolu, yer tutucular aynı', () {
      final problems = <String>[];
      L10n.table.forEach((source, row) {
        if (row.length != AppLanguage.values.length - 1) {
          problems.add('$source: ${row.length} çeviri (5 olmalı)');
          return;
        }
        final want = _placeholder.allMatches(source).map((m) => m[1]).toSet();
        for (final (i, text) in row.indexed) {
          if (!AppLanguage.active.contains(AppLanguage.values[i + 1])) continue;
          final lang = AppLanguage.values[i + 1].code;
          if (text.trim().isEmpty) problems.add('$source [$lang]: boş');
          final got = _placeholder.allMatches(text).map((m) => m[1]).toSet();
          if (got.length != want.length || !got.containsAll(want)) {
            problems.add('$source [$lang]: yer tutucular $got ≠ $want');
          }
        }
      });
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test("kodda t('…') ile istenen her metnin çevirisi var", () {
      final missing = <String>{};
      for (final file in _dartFiles('lib')) {
        final code = file.readAsStringSync();
        for (final m in _tCall.allMatches(code)) {
          final source = _unescape(m[1] ?? m[2]!);
          if (source.contains(r'$')) {
            missing.add(
              '${file.path}: t() içinde \$ (yer tutucu kullan): $source',
            );
          } else if (!L10n.table.containsKey(source)) {
            missing.add('${file.path}: "$source"');
          }
        }
      }
      expect(missing, isEmpty, reason: missing.join('\n'));
    });

    test('ekranda çevrilmeden kalan Türkçe metin yok', () {
      final left = <String>[];
      for (final dir in ['lib/screens', 'lib/widgets', 'lib/core']) {
        for (final file in _dartFiles(dir)) {
          final lines = file.readAsLinesSync();
          final code = lines.join('\n');
          for (final m in _shown.allMatches(code)) {
            final literal = m[1] ?? m[2]!;
            if (!_latinWord.hasMatch(
              literal.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), ''),
            )) {
              continue;
            }
            final line = code.substring(0, m.start).split('\n').length;
            if (lines[line - 1].contains('l10n-ignore')) continue;
            left.add('${file.path}:$line  $literal');
          }
        }
      }
      expect(left, isEmpty, reason: left.join('\n'));
    });
  });

  group('dil tercihi', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('cihaz dili desteklenirse varsayılan o, yoksa Türkçe', () {
      expect(
        AppLanguage.fromDeviceLocales(const [Locale('fr', 'FR')]),
        AppLanguage.fr,
      );
      expect(
        AppLanguage.fromDeviceLocales(const [Locale('ar'), Locale('bs')]),
        AppLanguage.tr,
      );
      expect(
        AppLanguage.fromDeviceLocales(const [Locale('ar')]),
        AppLanguage.tr,
      );
      // Boşnakça kendi kodu; Hırvatça/Sırpça Boşnakça sayılmaz.
      expect(
        AppLanguage.fromDeviceLocales(const [Locale('hr')]),
        AppLanguage.tr,
      );
    });

    test('dil adları kendi dilinde, kodlar ayrı', () {
      expect(
        {for (final l in AppLanguage.values) l.code: l.nativeName},
        {
          'tr': 'Türkçe',
          'es': 'Español',
          'fr': 'Français',
          'de': 'Deutsch',
          'en': 'English',
          'bs': 'Bosanski',
        },
      );
    });

    test('elle seçim kalıcı ve cihaz dilini geçer', () async {
      final first = LanguageController(
        deviceLocales: const [Locale('en', 'US')],
      );
      await first.load();
      expect(first.language, AppLanguage.en);
      expect(first.chosen, isFalse);
      await first.setLanguage(AppLanguage.fr);
      expect(first.language, AppLanguage.fr);

      final again = LanguageController(
        deviceLocales: const [Locale('en', 'US')],
      );
      await again.load();
      expect(again.language, AppLanguage.fr);
      expect(again.chosen, isTrue);
    });

    testWidgets('kapsam yoksa Türkçe; dil değişince metin değişir', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: (c) => Text(c.t('Sonraki Sayfa'))),
        ),
      );
      expect(find.text('Sonraki Sayfa'), findsOneWidget);

      final controller = LanguageController(initial: AppLanguage.tr);
      await tester.pumpWidget(
        AppLanguageScope(
          controller: controller,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(builder: (c) => Text(c.t('Sonraki Sayfa'))),
          ),
        ),
      );
      expect(find.text('Sonraki Sayfa'), findsOneWidget);
      await controller.setLanguage(AppLanguage.en);
      await tester.pump();
      expect(find.text('Next Page'), findsOneWidget);
      await controller.setLanguage(AppLanguage.de);
      await tester.pump();
      expect(find.text('Nächste Seite'), findsOneWidget);
    });
  });
}
