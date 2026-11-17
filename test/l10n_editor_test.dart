import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_8_bit_cpu_simulator/core/assembler.dart';
import 'package:flutter_8_bit_cpu_simulator/core/builtin_program_list.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu_mode.dart';
import 'package:flutter_8_bit_cpu_simulator/l10n/editor_strings.dart';
import 'package:flutter_8_bit_cpu_simulator/l10n/l10n.dart';

void main() {
  tearDown(() => L10n.debugSet(Lang.en));

  /// A few representative strings in [lang].
  List<String> sample(Lang lang) {
    L10n.debugSet(lang);
    final t = tEditor;
    return [
      t.programTitle,
      t.builtinPrograms,
      t.instructionSet,
      t.statusAssembled(5, 16),
      t.assembledFor(CpuMode.extended, 12, 256),
      t.switchesTo(CpuMode.classic),
      t.categoryName(BuiltinProgramCategory.controlFlow),
      t.programName(BuiltinProgramId.fibonacci),
      t.programDescription(BuiltinProgramId.keypadEcho),
      t.unknownInstruction('FOO'),
    ];
  }

  test('each language gives non-empty, distinct editor text', () {
    final en = sample(Lang.en);
    final fr = sample(Lang.fr);
    final de = sample(Lang.de);
    for (var i = 0; i < en.length; i++) {
      for (final s in [en[i], fr[i], de[i]]) {
        expect(s, isNotEmpty);
      }
      expect({en[i], fr[i], de[i]}, hasLength(3), reason: en[i]);
    }
  });

  test('every built-in program has a name and description per language', () {
    for (final lang in Lang.values) {
      L10n.debugSet(lang);
      final names = BuiltinProgramList.all.map((p) => p.name).toSet();
      expect(names, hasLength(BuiltinProgramList.all.length));
      for (final p in BuiltinProgramList.all) {
        expect(p.description, isNotEmpty);
        expect(p.category.label, isNotEmpty);
      }
    }
  });

  test('programs are found by their English name in any language', () {
    L10n.debugSet(Lang.de);
    final program = BuiltinProgramList.getByName('Powers of 2');
    expect(program?.name, 'Zweierpotenzen');
  });

  test('assembler errors follow the language', () {
    String errorOf(String source) {
      try {
        Assembler().assemble(source);
      } on AssemblerError catch (e) {
        return e.toString();
      }
      fail('expected an AssemblerError');
    }

    expect(errorOf('FOO'), 'Line 1: Unknown instruction "FOO"');
    L10n.debugSet(Lang.fr);
    expect(errorOf('FOO'), 'Ligne 1 : Instruction inconnue « FOO »');
    L10n.debugSet(Lang.de);
    expect(errorOf('FOO'), 'Zeile 1: Unbekannter Befehl „FOO“');
  });
}
