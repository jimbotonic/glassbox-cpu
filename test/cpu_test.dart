import 'package:flutter_8_bit_cpu_simulator/core/assembler.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu.dart';
import 'package:flutter_8_bit_cpu_simulator/core/microcode.dart';
import 'package:flutter_8_bit_cpu_simulator/core/opcode.dart';
import 'package:flutter_test/flutter_test.dart';

/// CPU loaded with [source]; [data] is written at the given addresses.
Cpu cpuWith(String source, {Map<int, int> data = const {}}) {
  final cpu = Cpu()..load(Assembler().assemble(source));
  data.forEach(cpu.writeRam);
  return cpu;
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
  group('fetch', () {
    test('T0 copies PC to MAR, T1 loads IR and increments PC', () {
      final cpu = cpuWith('LDI #9\nHLT');

      cpu.tick();
      expect(Microcode.describe(cpu.controlWord), 'MI|CO');
      expect(cpu.memoryAddressRegister, 0);
      expect(cpu.bus, 0);
      expect(cpu.busActive, isTrue);

      cpu.tick();
      expect(Microcode.describe(cpu.controlWord), 'RO|II|CE');
      expect(cpu.instructionRegister, 0x59);
      expect(cpu.programCounter, 1);
    });

    test('instruction address is latched at T0', () {
      final cpu = cpuWith('NOP\nNOP\nHLT');
      cpu.stepInstruction();
      expect(cpu.instructionAddress, 0);
      cpu.tick(); // T0 of the second NOP
      expect(cpu.instructionAddress, 1);
    });

    test('program counter wraps from 15 to 0', () {
      final cpu = Cpu()..load(List.filled(16, 0x00)); // 16 NOPs
      for (int i = 0; i < 16; i++) {
        cpu.stepInstruction();
      }
      expect(cpu.programCounter, 0);
    });
  });

  group('microcode table', () {
    const expectedSteps = {
      Opcode.nop: 3,
      Opcode.lda: 4,
      Opcode.add: 5,
      Opcode.sub: 5,
      Opcode.sta: 4,
      Opcode.ldi: 3,
      Opcode.jmp: 3,
      Opcode.jc: 3,
      Opcode.jz: 3,
      Opcode.out: 3,
      Opcode.hlt: 3,
    };

    expectedSteps.forEach((opcode, steps) {
      test('${opcode.mnemonic} takes $steps cycles', () {
        expect(Microcode.stepCount(opcode), steps);
      });
    });

    test('every opcode has an entry', () {
      for (final opcode in Opcode.values) {
        expect(() => Microcode.executeSteps(opcode), returnsNormally);
      }
    });
  });

  group('instructions', () {
    test('NOP changes nothing but the program counter', () {
      final cpu = cpuWith('NOP\nHLT');
      expect(traceInstruction(cpu), ['MI|CO', 'RO|II|CE', '-']);
      expect(cpu.registerA, 0);
      expect(cpu.programCounter, 1);
    });

    test('LDA loads A from RAM', () {
      final cpu = cpuWith('LDA 0xF\nHLT', data: {0xF: 42});
      expect(traceInstruction(cpu), ['MI|CO', 'RO|II|CE', 'MI|IO', 'RO|AI']);
      expect(cpu.registerA, 42);
      expect(cpu.memoryAddressRegister, 0xF);
    });

    test('LDI loads a 4-bit immediate into A', () {
      final cpu = cpuWith('LDI #15\nHLT');
      expect(traceInstruction(cpu), ['MI|CO', 'RO|II|CE', 'IO|AI']);
      expect(cpu.registerA, 15);
    });

    test('ADD adds RAM to A through B and sets flags', () {
      final cpu = cpuWith('LDA 0xE\nADD 0xF\nHLT', data: {0xE: 20, 0xF: 22});
      cpu.stepInstruction();
      expect(traceInstruction(cpu), [
        'MI|CO',
        'RO|II|CE',
        'MI|IO',
        'RO|BI',
        'AI|SO|FI',
      ]);
      expect(cpu.registerA, 42);
      expect(cpu.registerB, 22);
      expect(cpu.sumRegister, 42);
      expect(cpu.carryFlag, isFalse);
      expect(cpu.zeroFlag, isFalse);
    });

    test('ADD past 255 wraps and sets carry', () {
      final cpu = cpuWith('LDA 0xE\nADD 0xF\nHLT', data: {0xE: 200, 0xF: 100});
      cpu.run();
      expect(cpu.registerA, 44);
      expect(cpu.carryFlag, isTrue);
      expect(cpu.zeroFlag, isFalse);
    });

    test('ADD to exactly 256 sets carry and zero', () {
      final cpu = cpuWith('LDA 0xE\nADD 0xF\nHLT', data: {0xE: 255, 0xF: 1});
      cpu.run();
      expect(cpu.registerA, 0);
      expect(cpu.carryFlag, isTrue);
      expect(cpu.zeroFlag, isTrue);
    });

    test('SUB subtracts with SU active', () {
      final cpu = cpuWith('LDA 0xE\nSUB 0xF\nHLT', data: {0xE: 5, 0xF: 3});
      cpu.stepInstruction();
      expect(traceInstruction(cpu).last, 'AI|SO|SU|FI');
      expect(cpu.registerA, 2);
      expect(cpu.carryFlag, isFalse);
      expect(cpu.zeroFlag, isFalse);
    });

    test('SUB below zero wraps and sets carry (borrow)', () {
      final cpu = cpuWith('LDA 0xE\nSUB 0xF\nHLT', data: {0xE: 3, 0xF: 5});
      cpu.run();
      expect(cpu.registerA, 254);
      expect(cpu.carryFlag, isTrue);
    });

    test('SUB to zero sets zero', () {
      final cpu = cpuWith('LDA 0xE\nSUB 0xF\nHLT', data: {0xE: 7, 0xF: 7});
      cpu.run();
      expect(cpu.registerA, 0);
      expect(cpu.zeroFlag, isTrue);
      expect(cpu.carryFlag, isFalse);
    });

    test('STA writes A to RAM', () {
      final cpu = cpuWith('LDI #9\nSTA 0xC\nHLT');
      cpu.stepInstruction();
      expect(traceInstruction(cpu), ['MI|CO', 'RO|II|CE', 'MI|IO', 'RI|AO']);
      expect(cpu.ram[0xC], 9);
    });

    test('JMP loads the program counter', () {
      final cpu = cpuWith('JMP 0x5\nHLT');
      expect(traceInstruction(cpu).last, 'IO|J');
      expect(cpu.programCounter, 5);
    });

    test('JC jumps only when carry is set', () {
      final notTaken = cpuWith('JC 0x5\nHLT');
      expect(traceInstruction(notTaken).last, '-');
      expect(notTaken.programCounter, 1);

      final taken = cpuWith('JC 0x5\nHLT')..carryFlag = true;
      expect(traceInstruction(taken).last, 'IO|J');
      expect(taken.programCounter, 5);
    });

    test('JZ jumps only when zero is set', () {
      final notTaken = cpuWith('JZ 0x5\nHLT');
      expect(traceInstruction(notTaken).last, '-');
      expect(notTaken.programCounter, 1);

      final taken = cpuWith('JZ 0x5\nHLT')..zeroFlag = true;
      expect(traceInstruction(taken).last, 'IO|J');
      expect(taken.programCounter, 5);
    });

    test('OUT copies A to the output register and reports it', () {
      final outputs = <int>[];
      final cpu = cpuWith('LDI #7\nOUT\nHLT')..onOutput = outputs.add;
      cpu.stepInstruction();
      expect(traceInstruction(cpu).last, 'AO|OI');
      expect(cpu.outputRegister, 7);
      expect(outputs, [7]);
    });

    test('HLT stops the clock', () {
      final cpu = cpuWith('HLT\nLDI #1');
      expect(traceInstruction(cpu).last, 'HLT');
      expect(cpu.halted, isTrue);
      expect(cpu.busActive, isFalse);

      cpu.tick();
      expect(cpu.programCounter, 1, reason: 'no fetch after halting');
      expect(cpu.registerA, 0);
    });
  });

  group('step and reset', () {
    test('stepInstruction from mid-instruction finishes it', () {
      final cpu = cpuWith('LDA 0xF\nHLT', data: {0xF: 3});
      cpu.tick();
      cpu.tick();
      cpu.stepInstruction();
      expect(cpu.microStep, 0);
      expect(cpu.registerA, 3);
      expect(cpu.programCounter, 1);
    });

    test('reset restores the loaded program and clears state', () {
      final cpu = cpuWith('LDI #9\nSTA 0x0\nHLT');
      cpu.run();
      expect(cpu.ram[0], 9, reason: 'program overwrote its first byte');

      cpu.reset();
      expect(cpu.ram[0], 0x59);
      expect(cpu.registerA, 0);
      expect(cpu.halted, isFalse);
      expect(cpu.microStep, 0);
      expect(cpu.instructionAddress, 0);
    });

    test('run stops at maxTicks for programs that never halt', () {
      final cpu = cpuWith('JMP 0x0');
      expect(cpu.run(maxTicks: 30), 30);
      expect(cpu.halted, isFalse);
    });
  });
}
