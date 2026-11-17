import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu_mode.dart';
import 'package:flutter_8_bit_cpu_simulator/core/disassembler.dart';
import 'package:flutter_8_bit_cpu_simulator/core/opcode.dart';
import 'package:flutter_8_bit_cpu_simulator/l10n/isa_strings.dart';
import 'package:flutter_8_bit_cpu_simulator/l10n/l10n.dart';

void main() {
  tearDown(() => L10n.debugSet(Lang.en));

  IsaStrings stringsIn(Lang lang) {
    L10n.debugSet(lang);
    return tIsa;
  }

  test('the cards cover every opcode, each once', () {
    final covered = [for (final card in IsaCard.values) ...card.opcodes];
    expect(covered.toSet(), Opcode.values.toSet());
    expect(covered.length, Opcode.values.length);
  });

  test('every card has its text in every language', () {
    for (final lang in Lang.values) {
      final t = stringsIn(lang);
      for (final card in IsaCard.values) {
        final e = t.entry(card);
        expect(e.description, isNotEmpty, reason: '$lang $card');
        expect(e.operand, isNotEmpty, reason: '$lang $card');
        expect(e.behavior, isNotEmpty, reason: '$lang $card');
      }
    }
  });

  test('an example comment exists in all languages or in none', () {
    final en = stringsIn(Lang.en);
    final fr = stringsIn(Lang.fr);
    final de = stringsIn(Lang.de);
    for (final card in IsaCard.values) {
      final hasNote = en.entry(card).exampleNote != null;
      expect(fr.entry(card).exampleNote != null, hasNote, reason: '$card');
      expect(de.entry(card).exampleNote != null, hasNote, reason: '$card');
    }
  });

  test('descriptions and behaviour differ from English', () {
    final en = stringsIn(Lang.en);
    for (final lang in [Lang.fr, Lang.de]) {
      final t = stringsIn(lang);
      for (final card in IsaCard.values) {
        expect(
          t.entry(card).description,
          isNot(en.entry(card).description),
          reason: '$lang $card',
        );
        expect(
          t.entry(card).behavior,
          isNot(en.entry(card).behavior),
          reason: '$lang $card',
        );
      }
    }
  });

  test('representative strings are distinct per language', () {
    final texts = {
      for (final lang in Lang.values)
        lang: () {
          final t = stringsIn(lang);
          return [
            t.title,
            t.extendedIntro,
            t.operandTypes,
            t.portMap,
            t.port(5).$1,
            t.lcdNote,
            t.syntaxTitle,
            t.syntaxNote,
            t.operandRow,
          ];
        }(),
    };
    for (final list in texts.values) {
      for (final s in list) {
        expect(s, isNotEmpty);
      }
    }
    for (var i = 0; i < texts[Lang.en]!.length; i++) {
      final set = {for (final lang in Lang.values) texts[lang]![i]};
      expect(set.length, 3, reason: 'string $i');
    }
  });

  test('the worked example keeps the same code in every language', () {
    String code(Lang lang) => stringsIn(
      lang,
    ).syntaxExample.split('\n').map((l) => l.split(';').first).join('\n');
    expect(code(Lang.fr), code(Lang.en));
    expect(code(Lang.de), code(Lang.en));
  });

  test('the RAM sweep marks operand bytes in the current language', () {
    const extended = CpuMode.extended;
    L10n.debugSet(Lang.fr);
    expect(
      Disassembler.sweep([0x19, 5, 0x0F], mode: extended)[1],
      '  ↳ opérande',
    );
    L10n.debugSet(Lang.de);
    expect(
      Disassembler.sweep([0x19, 5, 0x0F], mode: extended)[1],
      '  ↳ Operand',
    );
  });
}
