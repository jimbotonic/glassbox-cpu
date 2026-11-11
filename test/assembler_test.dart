import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_8_bit_cpu_simulator/core/assembler.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu.dart';

void main() {
  final assembler = Assembler();

  /// The error message thrown when assembling [source].
  String errorOf(String source) {
    try {
      assembler.assemble(source);
    } on AssemblerError catch (e) {
      return e.toString();
    }
    fail('expected an AssemblerError for:\n$source');
  }

  test('source map skips blank and comment-only lines', () {
    const source =
        '; multiply 7 x 3\n'
        'LDI #7\n'
        '\n'
        'STA 0xF   ; keep 7\n'
        '  ; comment only\n'
        'ADD 0xF\n'
        'HLT';

    final result = assembler.assembleWithSourceMap(source);

    expect(result.machineCode, [0x57, 0x4F, 0x2F, 0xF0]);
    expect(result.sourceLines, [1, 3, 5, 6]);
    expect(result.lineForAddress(0), 1);
    expect(result.lineForAddress(3), 6);
    expect(result.lineForAddress(4), isNull);
    expect(result.lineForAddress(-1), isNull);
  });

  test('assemble returns the same machine code as the source-map variant', () {
    const source = 'LDI #3\nOUT\nHLT';
    expect(
      assembler.assemble(source),
      assembler.assembleWithSourceMap(source).machineCode,
    );
  });

  group('labels', () {
    test('resolve backward and forward references', () {
      const source =
          'loop: LDA count\n'
          '      JZ done\n'
          '      JMP loop\n'
          'done: HLT\n'
          'count: .db 3';
      final result = assembler.assembleWithSourceMap(source);
      expect(result.machineCode, [0x14, 0x83, 0x60, 0xF0, 0x03]);
      expect(result.symbols, {'LOOP': 0, 'DONE': 3, 'COUNT': 4});
    });

    test('a label alone on a line names the next address', () {
      const source = 'LDI #1\nagain:\n\nOUT\nJMP again';
      expect(assembler.assemble(source), [0x51, 0xE0, 0x61]);
    });

    test('are not case-sensitive', () {
      expect(assembler.assemble('Top: JMP TOP'), [0x60]);
    });

    test('reject duplicates, unknown names, and mnemonics as names', () {
      expect(errorOf('a: NOP\na: NOP'), 'Line 2: "a" is already defined');
      expect(errorOf('JMP nowhere'), 'Line 1: Unknown name "nowhere"');
      expect(
        errorOf('out: NOP'),
        'Line 1: "out" is an instruction and cannot be a name',
      );
    });
  });

  group('.equ', () {
    test('defines constants usable as operands and data', () {
      const source =
          '.equ START 9\n'
          '.equ ADDR, 0xF\n'
          'LDI #START\n'
          'STA ADDR\n'
          'HLT\n'
          '.db START';
      expect(assembler.assemble(source), [0x59, 0x4F, 0xF0, 0x09]);
    });

    test('takes no space in RAM', () {
      final result = assembler.assembleWithSourceMap('.equ X 1\nLDI X');
      expect(result.machineCode, [0x51]);
      expect(result.sourceLines, [1]);
    });

    test('rejects a malformed definition', () {
      expect(errorOf('.equ X'), 'Line 1: Expected ".equ NAME value"');
      expect(errorOf('.equ 1X 2'), 'Line 1: Expected ".equ NAME value"');
    });
  });

  group('.db', () {
    test('emits values, labels, strings and characters', () {
      const source =
          'start: .db 1, 0x2A, 0b101, 255, -1\n'
          '.db "Hi", \'!\', start';
      expect(assembler.assemble(source), [
        1,
        0x2A,
        5,
        255,
        0xFF,
        0x48,
        0x69,
        0x21,
        0,
      ]);
    });

    test('keeps commas and semicolons inside strings', () {
      expect(assembler.assemble('.db "a,b;c" ; comment'), [
        0x61,
        0x2C,
        0x62,
        0x3B,
        0x63,
      ]);
    });

    test('supports escapes', () {
      expect(assembler.assemble(r'''.db "\"\\\n", '\'' '''), [
        0x22,
        0x5C,
        0x0A,
        0x27,
      ]);
    });

    test('marks its addresses as data, not instructions', () {
      final result = assembler.assembleWithSourceMap('LDA x\nHLT\nx: .db 7, 8');
      expect(result.dataAddresses, {2, 3});
      expect(result.addressForLine(0), 0);
      expect(result.addressForLine(2), isNull);
      expect(result.addressesForLine(2), [2, 3]);
      expect(result.lineForAddress(3), 2);
    });

    test('rejects out-of-range bytes and empty items', () {
      expect(errorOf('.db 256'), 'Line 1: Byte must be -128..255, got 256');
      expect(errorOf('.db 1,,2'), 'Line 1: Missing value in .db');
      expect(errorOf('.db'), 'Line 1: .db needs at least one value');
      expect(errorOf('.db "abc'), 'Line 1: Unterminated literal "abc');
    });
  });

  group('errors', () {
    test('carry the line number', () {
      try {
        assembler.assemble('NOP\nFOO 1');
        fail('expected an error');
      } on AssemblerError catch (e) {
        expect(e.line, 2);
        expect(e.message, 'Unknown instruction "FOO"');
      }
    });

    test('cover operands, directives and program size', () {
      expect(errorOf('LDA'), 'Line 1: LDA requires an operand');
      expect(errorOf('LDA 16'), 'Line 1: Operand must be 0-15 (4-bit), got 16');
      expect(errorOf('LDA 1 2'), 'Line 1: Unexpected "2"');
      expect(errorOf('LDA 0xZ'), 'Line 1: Invalid operand "0xZ"');
      expect(errorOf('.org 4'), 'Line 1: Unknown directive ".org"');
      expect(errorOf('; nothing'), 'Program is empty');
      expect(
        errorOf('.db "${'x' * 17}"'),
        'Program needs 17 bytes but RAM holds only 16',
      );
    });
  });

  test('a labelled program runs on the CPU', () {
    const source =
        '; count down from 3\n'
        '.equ START 3\n'
        '       LDI START\n'
        'loop:  OUT\n'
        '       SUB one\n'
        '       JZ  done\n'
        '       JMP loop\n'
        'done:  HLT\n'
        'one:   .db 1';
    final outputs = <int>[];
    final cpu = Cpu()
      ..load(assembler.assemble(source))
      ..onOutput = outputs.add
      ..run();
    expect(outputs, [3, 2, 1]);
    expect(cpu.halted, isTrue);
  });
}
