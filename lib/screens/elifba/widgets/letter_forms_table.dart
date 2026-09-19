import '../../../widgets/reading_text_settings.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/arabic_letter.dart';
import '../../../theme/app_text_theme.dart';

/// A continuous, book-style table of positional word examples.
class LetterFormsTable extends StatelessWidget {
  const LetterFormsTable({
    super.key,
    required this.letters,
    required this.onTapLetter,
    required this.onOpenLetter,
  });
  final List<ArabicLetter> letters;
  final ValueChanged<ArabicLetter> onTapLetter;
  final ValueChanged<int> onOpenLetter;
  static const _ink = Color(0xFF912E27);
  static const _line = Color(0xFFC5AE98);
  static const _paper = Color(0xFFFFFCF5);

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF3EBDD),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _paper,
              border: Border.all(color: _line, width: 2),
            ),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: _line)),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAEACB),
                      border: Border.symmetric(
                        horizontal: BorderSide(color: _line),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFC49B46),
                          size: 26,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'HARFLERİN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ink,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'BAŞTA, ORTADA, SONDA\nYAZILIŞLARINA ÖRNEKLER',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ink,
                            fontSize: 17,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18, horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Harflerin kelimelere nasıl bitiştiğini inceleyelim. '
                          'ا، د، ذ، ر، ز، و harfleri kendilerinden sonra gelen harfe bitişmez.',
                          style: TextStyle(fontSize: 14, height: 1.6),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Not: Henüz harekeleri öğrenmedik. Kelimeleri okumaya değil, '
                          'kırmızı harflerin yazılışına dikkat edelim.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final scale = MediaQuery.textScalerOf(context).scale(1);
                      final width = math.max(constraints.maxWidth, 300 * scale);
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: SizedBox(width: width, child: _table(context)),
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 18, bottom: 8),
                    child: Text(
                      'Harfe dokunarak dinleyin. Basılı tutarak tek harf görünümünü açın.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _ink, fontSize: 12, height: 1.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 472),
                      child: Image.asset(
                        'assets/lazim/ders2icinsayfa_alti.png',
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _table(BuildContext context) => Table(
    textDirection: TextDirection.rtl,
    columnWidths: const {
      0: FlexColumnWidth(0.9),
      1: FlexColumnWidth(),
      2: FlexColumnWidth(),
      3: FlexColumnWidth(),
    },
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    border: TableBorder.all(color: _line, width: 0.8),
    children: [
      TableRow(
        decoration: const BoxDecoration(color: Color(0xFFFAE3BA)),
        children: [
          for (final label in ['HARF', 'BAŞTA', 'ORTADA', 'SONDA'])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
            ),
        ],
      ),
      for (var i = 0; i < letters.length; i++) ...[
        TableRow(
          children: [
            Semantics(
              button: true,
              label: '${letters[i].turkishName} harfini dinle',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTapLetter(letters[i]),
                  onLongPress: () => onOpenLetter(i),
                  child: _word(
                    context,
                    '[${letters[i].isolatedForm}]',
                    isMainLetter: true,
                  ),
                ),
              ),
            ),
            for (var position = 0; position < 3; position++)
              if (i == 0 && position == 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                  child: Column(
                    children: [
                      Text('×', style: TextStyle(fontSize: 28)),
                      Text(
                        'Elif kelimenin başında bulunmaz; hemze bulunur.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                )
              else
                _word(context, _example(letters[i], position)),
          ],
        ),
        if (i == 0)
          TableRow(
            children: [
              _word(context, '[أ]', isMainLetter: true),
              _word(context, '[ا]ذن\n[أ]ذن\n[إ]رم'),
              _word(context, 'س[ا]ل\nس[أ]ل\nي[ئ]س\nر[ؤ]س'),
              _word(context, 'نب[ا]\nنب[أ]\nنب[إ]\nقر[ئ]'),
            ],
          ),
      ],
    ],
  );

  String _example(ArabicLetter letter, int position) {
    final target = letter.isolatedForm.replaceAll('ـ', '');
    final reference = _examples[target];
    if (reference != null) return reference[position];
    final word = letter.positionExamples![position];
    final index =
        position == 2 ? word.lastIndexOf(target) : word.indexOf(target);
    if (index < 0) return word;
    return '${word.substring(0, index)}[$target]${word.substring(index + target.length)}';
  }

  Widget _word(
    BuildContext context,
    String marked, {
    bool isMainLetter = false,
  }) {
    final spans = <TextSpan>[];
    for (final match in RegExp(r'\[([^\]]+)\]|([^\[]+)').allMatches(marked)) {
      spans.add(
        TextSpan(
          text: match.group(1) ?? match.group(2),
          style: TextStyle(
            color: match.group(1) != null ? _ink : const Color(0xFF22201E),
          ),
        ),
      );
    }
    return Container(
      decoration:
          isMainLetter
              ? BoxDecoration(
                color: const Color(0xFFFAEACB),
                border: Border.all(color: _line.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(6),
              )
              : null,
      margin: isMainLetter ? const EdgeInsets.all(4) : null,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 22),
      child: ReadingFittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(children: spans),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: AppTextTheme.arabicSmall(
            fontSize: isMainLetter ? 46 : 38,
          ).copyWith(height: 1.6),
        ),
      ),
    );
  }

  // Brackets mark the letter being taught, within a single shaped text run.
  static const _examples = <String, List<String>>{
    'ا': ['', 'ب[ا]رك', 'وم[ا]'],
    'ب': ['[ب]رز', 'ل[ب]رز', 'ذه[ب]'],
    'ت': ['[ت]رك', 'ك[ت]ب', 'سك[ت]\nكلم[ة]\nامرأ[ة]'],
    'ث': ['[ث]قلت', 'م[ث]ل', 'بع[ث]'],
    'ج': ['[ج]عل', 'ت[ج]د', 'يل[ج]'],
    'ح': ['[ح]ول', 'ن[ح]ن', 'فت[ح]'],
    'خ': ['[خ]لت', 'ت[خ]رج', 'نف[خ]'],
    'د': ['[د]مت', 'ب[د]أ', 'تج[د]'],
    'ذ': ['[ذ]هب', 'ت[ذ]ر', 'أخ[ذ]'],
    'س': ['[س]أل', 'ح[س]د', 'يئ[س]'],
    'ش': ['[ش]رب', 'ي[ش]رب', 'بط[ش]'],
    'ص': ['[ص]دق', 'ح[ص]حص', 'حصح[ص]'],
    'ض': ['[ض]يف', 'ح[ض]ر', 'أنق[ض]'],
    'ط': ['[ط]رفك', 'ب[ط]ش', 'يبس[ط]'],
    'ظ': ['[ظ]لم', 'ن[ظ]ر', 'حف[ظ]'],
    'ع': ['[ع]ن', 'ف[ع]ل', 'طب[ع]'],
    'غ': ['[غ]ير', 'ي[غ]نى', 'أسب[غ]'],
    'ف': ['[ف]قد', 'ح[ف]ظ', 'ضي[ف]'],
    'ق': ['[ق]بل', 'ف[ق]د', 'صد[ق]'],
    'ك': ['[ك]تب', 'ب[ك]ت', 'أتت[ك]'],
    'ل': ['[ل]ك', 'ت[ل]ك', 'رج[ل]'],
    'م': ['[م]رج', 'ث[م]ره', 'ظل[م]'],
    'ن': ['[ن]ظر', 'م[ن]ع', 'ع[ن]'],
    'و': ['[و]رد', 'س[و]ف', 'ل[و]'],
    'ه': ['[ه]و', 'ف[ه]و', 'ل[ه]'],
    'ي': ['[ي]لد', 'ض[ي]ف', 'ف[ي]'],
  };
}
