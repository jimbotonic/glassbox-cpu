import 'package:flutter_8_bit_cpu_simulator/core/assembler.dart';
import 'package:flutter_8_bit_cpu_simulator/core/control_word.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu_mode.dart';
import 'package:flutter_8_bit_cpu_simulator/core/disassembler.dart';
import 'package:flutter_8_bit_cpu_simulator/core/microcode.dart';
import 'package:flutter_8_bit_cpu_simulator/core/opcode.dart';
import 'package:flutter_8_bit_cpu_simulator/core/step_info.dart';
import 'package:flutter_test/flutter_test.dart';

const extended = CpuMode.extended;

List<int> assemble(String source) => Assembler(mode: extended).assemble(source);

Cpu cpuWith(String source) => Cpu(mode: extended)..load(assemble(source));

/// Runs [source] to HLT and returns the values it output.
List<int> outputsOf(String source, {int maxTicks = 20000}) {
  final outputs = <int>[];
  final cpu = cpuWith(source)..onOutput = outputs.add;
  cpu.run(maxTicks: maxTicks);
  expect(cpu.halted, isTrue, reason: 'program should halt');
  return outputs;
}

/// Ticks one whole instruction and returns its control words, described.
List<String> traceInstruction(Cpu cpu) {
  final words = <String>[];
  do {
    cpu.tick();
    words.add(Microcode.describe(cpu.controlWord));
  } while (cpu.microStep != 0 && !cpu.halted);
  return words;
}

void main() {
  group('mode', () {
    test('Extended has 256 bytes and 8-bit addresses', () {
      final cpu = Cpu(mode: extended);
      expect(cpu.ram.length, 256);
      expect(extended.addressMask, 0xFF);
      expect(extended.hexAddress(0x2A), '0x2A');
      expect(CpuMode.classic.hexAddress(0xA), '0xA');
    });

    test('setMode resizes and clears RAM and drops the program', () {
      final cpu = Cpu()..load([0x51, 0xE0, 0xF0]);
      cpu.setMode(extended);
      expect(cpu.ram.length, 256);
      expect(cpu.ram.every((b) => b == 0), isTrue);
      expect(cpu.program, isEmpty);
      cpu.setMode(CpuMode.classic);
      expect(cpu.ram.length, 16);
    });

    test('Extended has 27 instructions, Classic 11', () {
      expect(Opcode.forMode(extended), hasLength(27));
      expect(Opcode.forMode(CpuMode.classic), hasLength(11));
      final codes = Opcode.values.map((op) => op.extended).toSet();
      expect(codes, hasLength(Opcode.values.length), reason: 'unique codes');
    });

    test('Classic microcode never uses Extended-only signals', () {
      final classicMask = ControlWord.classic.fold(0, (m, w) => m | w.hex);
      for (final op in Opcode.forMode(CpuMode.classic)) {
        for (final flags in [(false, false), (true, true)]) {
          final steps = [
            ...Microcode.fetch,
            ...Microcode.executeSteps(op, carry: flags.$1, zero: flags.$2),
          ];
          for (final word in steps) {
            expect(word & ~classicMask, 0, reason: op.mnemonic);
          }
        }
      }
    });
  });

  group('assembler', () {
    test('instructions with a value take two bytes', () {
      expect(assemble('LDI 200\nOUT\nHLT'), [0x05, 200, 0x0E, 0x0F]);
      expect(assemble('LDA 0x80'), [0x01, 0x80]);
      expect(assemble('SBI -1'), [0x0D, 0xFF]);
    });

    test('labels account for two-byte instructions', () {
      final code = assemble('JMP end\nNOP\nend: HLT');
      expect(code, [0x06, 0x03, 0x00, 0x0F]);
    });

    test('LDA [B] picks the indexed opcode', () {
      expect(assemble('LDA [B]'), [0x30]);
      expect(assemble('lda [ b ]'), [0x30]);
    });

    test('source map covers both bytes of an instruction', () {
      final result = Assembler(
        mode: extended,
      ).assembleWithSourceMap('LDI 1\nloop: OUT\nJMP loop');
      expect(result.sourceLines, [0, 0, 1, 2, 2]);
      expect(result.addressForLine(2), 3);
      expect(result.addressesForLine(0), [0, 1]);
    });

    test('rejects out-of-range operands and misplaced [B]', () {
      expect(() => assemble('LDA 256'), throwsA(isA<AssemblerError>()));
      expect(() => assemble('LDI -129'), throwsA(isA<AssemblerError>()));
      expect(() => assemble('JMP -1'), throwsA(isA<AssemblerError>()));
      expect(() => assemble('STA [B]'), throwsA(isA<AssemblerError>()));
      expect(() => assemble('PUSH 3'), throwsA(isA<AssemblerError>()));
    });

    test('Classic rejects Extended-only instructions, with the line', () {
      for (final source in ['NOP\nPUSH', 'NOP\nLDA [B]', 'NOP\nJNZ 0']) {
        try {
          Assembler().assemble(source);
          fail('expected an error for $source');
        } on AssemblerError catch (e) {
          expect(e.line, 2);
          expect(e.message, contains('Extended'));
        }
      }
    });

    test('programs larger than 256 bytes are rejected', () {
      final source = List.filled(129, 'LDI 1').join('\n');
      expect(() => assemble(source), throwsA(isA<AssemblerError>()));
    });
  });

  group('disassembler', () {
    test('sweep shows operand bytes as operands', () {
      final lines = Disassembler.sweep(
        assemble('LDI 7\nLDA 0x20\nLDA [B]\nHLT'),
        mode: extended,
      );
      expect(lines, [
        'LDI #7',
        '  ↳ operand',
        'LDA 0x20',
        '  ↳ operand',
        'LDA [B]',
        'HLT',
      ]);
    });
  });

  group('microcode', () {
    const expectedSteps = {
      Opcode.nop: 3,
      Opcode.ldi: 4,
      Opcode.lda: 5,
      Opcode.ldb: 5,
      Opcode.sta: 5,
      Opcode.ldaIndexed: 4,
      Opcode.add: 6,
      Opcode.cmp: 6,
      Opcode.adi: 5,
      Opcode.shl: 3,
      Opcode.jmp: 4,
      Opcode.out: 3,
      Opcode.hlt: 3,
      Opcode.push: 4,
      Opcode.pop: 5,
      Opcode.call: 6,
      Opcode.ret: 6,
    };
    expectedSteps.forEach((op, steps) {
      test('${op.usage} takes $steps cycles', () {
        expect(Microcode.stepCount(op, mode: extended), steps);
      });
    });

    test('no instruction is longer than maxStepCount', () {
      for (final op in Opcode.values) {
        for (final c in [false, true]) {
          for (final z in [false, true]) {
            expect(
              Microcode.stepCount(op, mode: extended, carry: c, zero: z),
              lessThanOrEqualTo(Microcode.maxStepCount(extended)),
            );
          }
        }
      }
    });

    test('LDI reads its operand byte at PC and steps past it', () {
      final cpu = cpuWith('LDI 0x42\nHLT');
      expect(traceInstruction(cpu), ['MI|CO', 'RO|II|CE', 'MI|CO', 'RO|AI|CE']);
      expect(cpu.registerA, 0x42);
      expect(cpu.programCounter, 2);
    });

    test('an untaken jump skips the operand in one step', () {
      final cpu = cpuWith('JZ 0x10\nHLT');
      expect(traceInstruction(cpu), ['MI|CO', 'RO|II|CE', 'CE']);
      expect(cpu.programCounter, 2);
    });
  });

  group('instructions', () {
    test('LDA, STA and LDB use full 8-bit addresses', () {
      final cpu = cpuWith('LDI 99\nSTA 0xC8\nLDB 0xC8\nLDA 0xC8\nHLT');
      cpu.run();
      expect(cpu.ram[0xC8], 99);
      expect(cpu.registerB, 99);
      expect(cpu.registerA, 99);
    });

    test('ADI and SBI set the flags', () {
      final cpu = cpuWith('LDI 250\nADI 10\nHLT');
      cpu.run();
      expect(cpu.registerA, 4);
      expect(cpu.carryFlag, isTrue);

      final cpu2 = cpuWith('LDI 5\nSBI 5\nHLT');
      cpu2.run();
      expect(cpu2.registerA, 0);
      expect(cpu2.zeroFlag, isTrue);
      expect(cpu2.carryFlag, isFalse);
    });

    test('AND, OR, XOR work bit by bit and clear carry', () {
      const data = 'm: .db 0b11110000';
      final and = cpuWith('LDI 0b10101010\nAND m\nHLT\n$data')..run();
      final or = cpuWith('LDI 0b10101010\nOR m\nHLT\n$data')..run();
      final xor = cpuWith('LDI 0b11110000\nXOR m\nHLT\n$data')..run();
      expect(and.registerA, 0xA0);
      expect(or.registerA, 0xFA);
      expect(xor.registerA, 0);
      expect(xor.zeroFlag, isTrue);
      expect(and.carryFlag, isFalse);
    });

    test('CMP sets flags and leaves A unchanged', () {
      final equal = cpuWith('LDI 7\nCMP v\nHLT\nv: .db 7')..run();
      expect(equal.registerA, 7);
      expect(equal.zeroFlag, isTrue);
      expect(equal.carryFlag, isFalse);

      final smaller = cpuWith('LDI 3\nCMP v\nHLT\nv: .db 7')..run();
      expect(smaller.registerA, 3);
      expect(smaller.zeroFlag, isFalse);
      expect(smaller.carryFlag, isTrue, reason: 'borrow: A < operand');
    });

    test('SHL and SHR shift into the carry', () {
      final left = cpuWith('LDI 0x81\nSHL\nHLT')..run();
      expect(left.registerA, 0x02);
      expect(left.carryFlag, isTrue);
      final right = cpuWith('LDI 0x81\nSHR\nHLT')..run();
      expect(right.registerA, 0x40);
      expect(right.carryFlag, isTrue);
    });

    test('JNZ and JNC jump when the flag is clear', () {
      expect(outputsOf('LDI 3\nl: OUT\nSBI 1\nJNZ l\nHLT'), [3, 2, 1]);
      expect(outputsOf('LDI 1\nl: OUT\nSHL\nJNC l\nHLT'), [
        1, 2, 4, 8, 16, 32, 64, 128, //
      ]);
    });

    test('LDA [B] loads from the address in B', () {
      final cpu = cpuWith('LDB p\nLDA [B]\nHLT\np: .db v\nv: .db 0x5A');
      cpu.run();
      expect(cpu.registerA, 0x5A);
    });

    test('PUSH and POP are last in, first out', () {
      final cpu = cpuWith('LDI 1\nPUSH\nLDI 2\nPUSH');
      cpu.stepInstruction();
      cpu.stepInstruction();
      expect(cpu.stackPointer, 0xFE);
      expect(cpu.ram[0xFF], 1);
      cpu.stepInstruction();
      cpu.stepInstruction();
      expect(cpu.stackPointer, 0xFD);
      expect(cpu.ram[0xFE], 2);

      expect(outputsOf('LDI 1\nPUSH\nLDI 2\nPUSH\nPOP\nOUT\nPOP\nOUT\nHLT'), [
        2,
        1,
      ]);
    });

    test('CALL saves the operand address, RET resumes after the CALL', () {
      final cpu = cpuWith('CALL fn\nOUT\nHLT\nfn: LDI 9\nRET');
      cpu.stepInstruction(); // CALL
      expect(cpu.programCounter, 4);
      expect(cpu.stackPointer, 0xFE);
      expect(cpu.ram[0xFF], 1, reason: 'address of the operand byte');
      cpu.stepInstruction(); // LDI 9
      cpu.stepInstruction(); // RET
      expect(cpu.programCounter, 2);
      expect(cpu.stackPointer, 0xFF);

      expect(outputsOf('CALL fn\nOUT\nHLT\nfn: LDI 9\nRET'), [9]);
    });

    test('nested calls return in order', () {
      const source = '''
        CALL a
        OUT
        HLT
a:      CALL b
        ADI 1
        RET
b:      LDI 40
        RET''';
      expect(outputsOf(source), [41]);
    });

    test('reset restores SP and snapshots round-trip it', () {
      final cpu = cpuWith('LDI 1\nPUSH\nHLT');
      cpu.stepInstruction();
      final saved = cpu.snapshot();
      cpu.run();
      expect(cpu.stackPointer, 0xFE);
      cpu.restore(saved);
      expect(cpu.stackPointer, 0xFF);
      cpu.run();
      cpu.reset();
      expect(cpu.stackPointer, Cpu.initialStackPointer);
    });
  });

  group('step info', () {
    test('names B and SP as bus sources, and SP moves', () {
      final cpu = cpuWith('LDB p\nLDA [B]\nPUSH\nHLT\np: .db 0');
      cpu.stepInstruction();
      cpu.tick();
      cpu.tick();
      cpu.tick(); // T2 of LDA [B]: BO|MI
      var info = StepInfo.of(cpu);
      expect(info.source, BusNode.registerB);
      expect(info.purpose, 'LDA [B]');
      expect(info.caption, 'B = 0x00 → bus → MAR');
      cpu.stepInstruction();

      cpu.tick();
      cpu.tick();
      cpu.tick(); // T2 of PUSH: SPO|MI
      info = StepInfo.of(cpu);
      expect(info.source, BusNode.stackPointer);
      cpu.tick(); // T3: AO|RI|SP-
      info = StepInfo.of(cpu);
      expect(info.caption, 'A = 0x0B → bus → RAM[0xFF];  SP − 1 → 0xFE');
    });

    test('purpose shows the 8-bit operand and ALU names the operation', () {
      final cpu = cpuWith('LDI 0x81\nSHL\nHLT');
      cpu.tick();
      cpu.tick();
      cpu.tick();
      expect(StepInfo.of(cpu).purpose, 'LDI #129');
      cpu.stepInstruction();
      cpu.stepInstruction();
      final info = StepInfo.of(cpu);
      expect(info.source, BusNode.alu);
      expect(info.caption, 'A << 1 = 0x02 → bus → A;  flags C=1 Z=0');
    });
  });
}
