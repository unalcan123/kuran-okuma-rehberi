import '../../data/surah_meanings.dart';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';

const _sourceTitles = {
  'tr': 'Kaynaklar',
  'es': 'Fuentes',
  'fr': 'Sources',
  'de': 'Quellen',
  'en': 'Sources',
  'bs': 'Izvori',
  'nl': 'Bronnen',
};

class SourcesEntry extends StatelessWidget {
  const SourcesEntry({super.key});
  @override
  Widget build(BuildContext context) => TextButton.icon(
    key: const ValueKey('home-sources'),
    icon: const Icon(Icons.library_books_outlined),
    label: Text(_sourceTitles[context.language.code]!),
    onPressed:
        () => Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/kaynaklar'),
            builder: (_) => const SourcesScreen(),
          ),
        ),
  );
}

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_sourceTitles[context.language.code]!)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SelectableText(
              'Arapça / العربية: Diyanet İşleri Başkanlığı\nhttps://kuran.diyanet.gov.tr/kuran\nYeni sureler: resmî Diyanet mushaf sayfaları.',
            ),
            const SizedBox(height: 20),
            for (final entry in kSurahMeanings['fatiha']!.entries)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppLanguage.fromCode(entry.key)!.nativeName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        '${entry.value.title} · ${entry.value.version}',
                      ),
                      SelectableText(
                        entry.key == 'tr'
                            ? 'https://tanzil.net/trans/tr.yildirim'
                            : entry.value.url.replaceAll(RegExp(r'/1$'), ''),
                      ),
                      const SizedBox(height: 8),
                      Text(entry.value.description),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              context.t('Kitap referansları'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const SelectableText(
              'Elifbe · ref · s. 37–41\nKullanıcının sağladığı kitap sayfaları\nTürkçe / Nederlands',
            ),
          ],
        ),
      ),
    ),
  );
}
