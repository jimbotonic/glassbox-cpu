import 'package:flutter_8_bit_cpu_simulator/core/assembler.dart';
import 'package:flutter_8_bit_cpu_simulator/core/builtin_program_list.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu_mode.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs the built-in program [name] until it halts, it has produced [limit]
/// outputs, or [maxTicks] cycles have passed.
({List<int> outputs, bool halted}) runProgram(
  String name, {
  int? limit,
  int maxTicks = 50000,
}) {
  final program = BuiltinProgramList.getByName(name);
  expect(program, isNotNull, reason: 'no built-in program named "$name"');

  final outputs = <int>[];
  final cpu = Cpu(mode: program!.mode)
    ..load(Assembler(mode: program.mode).assemble(program.code))
    ..onOutput = outputs.add;

  for (int i = 0; i < maxTicks && !cpu.halted; i++) {
    if (limit != null && outputs.length >= limit) break;
    cpu.tick();
  }
  return (outputs: outputs, halted: cpu.halted);
}

void main() {
  test('every built-in program assembles and fits in RAM', () {
    for (final program in BuiltinProgramList.all) {
      final code = Assembler(mode: program.mode).assemble(program.code);
      expect(
        code.length,
        lessThanOrEqualTo(program.mode.ramSize),
        reason: program.name,
      );
    }
  });

  group('programs that halt', () {
    test('Counter (0-255) outputs 0..255, then halts on wrap-around', () {
      final result = runProgram('Counter (0-255)');
      expect(result.outputs, List.generate(256, (i) => i));
      expect(result.halted, isTrue);
    });

    test('Powers of 2 outputs 1..128, then halts', () {
      final result = runProgram('Powers of 2');
      expect(result.outputs, [1, 2, 4, 8, 16, 32, 64, 128]);
      expect(result.halted, isTrue);
    });

    test('Multiplication (7 × 3) outputs 21', () {
      final result = runProgram('Multiplication (7 × 3)');
      expect(result.outputs, [21]);
      expect(result.halted, isTrue);
    });

    test('Countdown from 10 outputs 10..1, then halts', () {
      final result = runProgram('Countdown from 10');
      expect(result.outputs, [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
      expect(result.halted, isTrue);
    });

    test('Countdown (labels & data) matches the raw-address version', () {
      final result = runProgram('Countdown (labels & data)');
      expect(result.outputs, [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
      expect(result.halted, isTrue);
    });

    test('Even Numbers outputs 0..254, then halts', () {
      final result = runProgram('Even Numbers');
      expect(result.outputs, List.generate(128, (i) => i * 2));
      expect(result.halted, isTrue);
    });

    test('Multiples of 5 outputs 0..255, then halts on carry', () {
      final result = runProgram('Multiples of 5');
      expect(result.outputs, List.generate(52, (i) => i * 5));
      expect(result.halted, isTrue);
    });
  });

  group('Extended CPU programs', () {
    test('every one is marked Extended', () {
      for (final program in BuiltinProgramList.extendedPrograms) {
        expect(program.mode, CpuMode.extended, reason: program.name);
      }
    });

    test('Countdown (immediates & JNZ) outputs 10..1', () {
      final result = runProgram('Countdown (immediates & JNZ)');
      expect(result.outputs, [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
      expect(result.halted, isTrue);
    });

    test('Hello outputs the character codes of HELLO', () {
      final result = runProgram('Hello (string with LDA [B])');
      expect(String.fromCharCodes(result.outputs), 'HELLO');
      expect(result.halted, isTrue);
    });

    test('Stack reverse outputs 3 2 1', () {
      final result = runProgram('Stack reverse (PUSH / POP)');
      expect(result.outputs, [3, 2, 1]);
      expect(result.halted, isTrue);
    });

    test('Multiply outputs 13 × 11 = 143', () {
      final result = runProgram('Multiply (CALL, shifts, AND)');
      expect(result.outputs, [143]);
      expect(result.halted, isTrue);
    });

    test('Bouncing bit goes up to 128 and back', () {
      final result = runProgram('Bouncing bit (SHL / SHR)', limit: 17);
      expect(result.outputs, [
        1, 2, 4, 8, 16, 32, 64, 128, 64, 32, 16, 8, 4, 2, 1, 2, 4, //
      ]);
    });
  });

  group('programs that loop forever', () {
    test('Binary Blinker alternates 0 and 1', () {
      final result = runProgram('Binary Blinker', limit: 6);
      expect(result.outputs, [0, 1, 0, 1, 0, 1]);
      expect(result.halted, isFalse);
    });

    test('Fibonacci Sequence, wrapping at 8 bits', () {
      final result = runProgram('Fibonacci Sequence', limit: 15);
      expect(result.outputs, [
        0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, //
        (144 + 233) & 0xFF,
      ]);
    });

    test('Triangle Numbers', () {
      final result = runProgram('Triangle Numbers', limit: 10);
      expect(result.outputs, [1, 3, 6, 10, 15, 21, 28, 36, 45, 55]);
    });

    test('Square Numbers', () {
      final result = runProgram('Square Numbers', limit: 10);
      expect(result.outputs, [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]);
    });

    test('Alternating Pattern alternates 10 and 5', () {
      // The program's description says 10 and 20, but its code loads 5.
      final result = runProgram('Alternating Pattern', limit: 4);
      expect(result.outputs, [10, 5, 10, 5]);
    });
  });
}
