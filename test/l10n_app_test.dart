import 'package:flutter_8_bit_cpu_simulator/core/assembler.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu_mode.dart';
import 'package:flutter_8_bit_cpu_simulator/core/step_info.dart';
import 'package:flutter_8_bit_cpu_simulator/l10n/app_strings.dart';
import 'package:flutter_8_bit_cpu_simulator/l10n/l10n.dart';
import 'package:flutter_8_bit_cpu_simulator/ui/board/signal_roles.dart';
import 'package:flutter_test/flutter_test.dart';

/// Collects a few representative strings in the current language.
List<String> sample() {
  final t = tApp;
  final cpu = Cpu()..load(Assembler().assemble('LDA 0xE\nSUB 0xF\nHLT'));
  final ready = StepInfo.of(cpu);
  cpu.tick();
  final t0 = StepInfo.of(cpu);
  cpu.run();
  final halt = StepInfo.of(cpu);
  return [
    t.windowTooSmallTitle,
    t.reset,
    t.runToCursor,
    t.step,
    t.modeTooltip('a', 'b'),
    t.nextFetch('LDA 0xE', '0x0', 3),
    t.nextStep(2, 'LDA 0xE'),
    t.aboutCredits,
    CpuMode.extended.label,
    CpuMode.classic.description,
    ready.caption,
    t0.purpose,
    halt.caption,
    wordNote(0),
    signalGroups(CpuMode.extended).first.name,
  ];
}

void main() {
  tearDown(() => L10n.debugSet(Lang.en));

  test('every language gives non-empty, distinct text', () {
    final byLang = <Lang, List<String>>{};
    for (final lang in Lang.values) {
      L10n.debugSet(lang);
      final strings = sample();
      for (final s in strings) {
        expect(s, isNotEmpty, reason: '$lang');
      }
      byLang[lang] = strings;
    }
    for (int i = 0; i < byLang[Lang.en]!.length; i++) {
      final en = byLang[Lang.en]![i];
      expect(byLang[Lang.fr]![i], isNot(en), reason: 'fr #$i');
      expect(byLang[Lang.de]![i], isNot(en), reason: 'de #$i');
    }
  });

  test('narration translates the words, not the symbols', () {
    final cpu = Cpu()..load(Assembler().assemble('LDA 0xE\nHLT'));
    cpu.tick();
    L10n.debugSet(Lang.fr);
    expect(StepInfo.of(cpu).caption, 'PC = 0x00 → bus → MAR');
    expect(
      StepInfo.of(cpu).purpose,
      'lecture : adresse de l’instruction suivante',
    );
    L10n.debugSet(Lang.de);
    expect(StepInfo.of(cpu).caption, 'PC = 0x00 → Bus → MAR');
    expect(StepInfo.of(cpu).purpose, 'Holen: Adresse des nächsten Befehls');
  });

  test('credits keep both link placeholders in every language', () {
    for (final lang in Lang.values) {
      L10n.debugSet(lang);
      expect(tApp.aboutCredits, contains('{muaz}'));
      expect(tApp.aboutCredits, contains('{eater}'));
    }
  });
}
