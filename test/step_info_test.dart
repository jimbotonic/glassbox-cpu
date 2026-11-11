import 'package:flutter_8_bit_cpu_simulator/core/assembler.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu.dart';
import 'package:flutter_8_bit_cpu_simulator/core/step_info.dart';
import 'package:flutter_test/flutter_test.dart';

Cpu cpuWith(String source, {Map<int, int> data = const {}}) {
  final cpu = Cpu()..load(Assembler().assemble(source));
  data.forEach(cpu.writeRam);
  return cpu;
}

void main() {
  test('before the first step it says what comes next', () {
    final info = StepInfo.of(cpuWith('HLT'));
    expect(info.stepLabel, '--');
    expect(info.source, isNull);
    expect(info.caption, 'next step fetches the instruction at 0x0');
  });

  test('describes every step of LDA', () {
    final cpu = cpuWith('LDA 0xE\nHLT', data: {0xE: 7});
    final steps = <StepInfo>[];
    for (int i = 0; i < 4; i++) {
      cpu.tick();
      steps.add(StepInfo.of(cpu));
    }

    expect(steps.map((s) => s.stepLabel), ['T0', 'T1', 'T2', 'T3']);
    expect(steps.map((s) => s.caption), [
      'PC = 0x00 → bus → MAR',
      'RAM[0x0] = 0x1E → bus → IR;  PC + 1 → 0x1',
      'IR operand = 0x0E → bus → MAR',
      'RAM[0xE] = 0x07 → bus → A',
    ]);
    expect(steps[0].purpose, 'fetch: address of next instruction');
    expect(steps[2].purpose, 'LDA 0xE');
    expect(steps[3].source, BusNode.ram);
    expect(steps[3].destinations, [BusNode.registerA]);
    expect(steps[3].signals, 'RO|AI');
  });

  test('ALU step names the operation and the flags', () {
    final cpu = cpuWith('LDA 0xE\nSUB 0xF\nHLT', data: {0xE: 5, 0xF: 5});
    cpu.stepInstruction();
    cpu.stepInstruction();
    final info = StepInfo.of(cpu);
    expect(info.source, BusNode.alu);
    expect(info.caption, 'A − B = 0x00 → bus → A;  flags C=0 Z=1');
  });

  test('store, output, jump and halt', () {
    final cpu = cpuWith('LDI #9\nSTA 0xC\nOUT\nJMP 0x5\nNOP\nHLT');
    cpu.stepInstruction();
    expect(StepInfo.of(cpu).purpose, 'LDI #9');

    cpu.stepInstruction();
    expect(StepInfo.of(cpu).caption, 'A = 0x09 → bus → RAM[0xC]');

    cpu.stepInstruction();
    final out = StepInfo.of(cpu);
    expect(out.caption, 'A = 0x09 → bus → OUT');
    expect(out.destinations, [BusNode.output]);

    cpu.stepInstruction();
    expect(StepInfo.of(cpu).caption, 'IR operand = 0x05 → bus → PC');

    cpu.stepInstruction();
    expect(StepInfo.of(cpu).caption, 'clock stopped');
  });

  test('an untaken jump does nothing in its execute step', () {
    final cpu = cpuWith('JZ 0x3\nHLT');
    cpu.stepInstruction();
    final info = StepInfo.of(cpu);
    expect(info.stepLabel, 'T2');
    expect(info.signals, '-');
    expect(info.caption, 'nothing to do this cycle');
  });

  test('snapshot and restore round-trip the whole state', () {
    final cpu = cpuWith('LDI #9\nSTA 0xC\nHLT');
    cpu.tick();
    final saved = cpu.snapshot();
    final ticksBefore = cpu.executedStep;

    cpu.run();
    expect(cpu.halted, isTrue);
    expect(cpu.ram[0xC], 9);

    cpu.restore(saved);
    expect(cpu.halted, isFalse);
    expect(cpu.ram[0xC], 0);
    expect(cpu.registerA, 0);
    expect(cpu.microStep, 1);
    expect(cpu.executedStep, ticksBefore);

    cpu.run();
    expect(cpu.ram[0xC], 9, reason: 'replays identically after restore');
  });
}
