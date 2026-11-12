import 'control_word.dart';
import 'cpu.dart';
import 'microcode.dart';
import 'opcode.dart';

/// A module that can drive or read the bus.
enum BusNode {
  programCounter('PC'),
  ram('RAM'),
  instructionRegister('IR'),
  registerA('A'),
  registerB('B'),
  alu('ALU'),
  memoryAddress('MAR'),
  output('OUT'),
  stackPointer('SP');

  final String label;
  const BusNode(this.label);
}

/// Plain-language description of the micro-step a [Cpu] just executed:
/// who drove the bus, who read it, and what else changed.
class StepInfo {
  /// T-state that was executed, or null before the first step.
  final int? step;
  final int controlWord;

  /// What the step is for, e.g. `fetch: load instruction` or `LDA 0xE`.
  final String purpose;

  /// Module that drove the bus, or null if nothing did.
  final BusNode? source;

  /// Modules that latched the bus value.
  final List<BusNode> destinations;

  /// The bus transfer, e.g. `RAM[0xE] = 0x07 → bus → A`; empty if none.
  final String transfer;

  /// Other effects: counter increment, flags, halt.
  final List<String> effects;

  const StepInfo({
    required this.step,
    required this.controlWord,
    required this.purpose,
    required this.source,
    required this.destinations,
    required this.transfer,
    required this.effects,
  });

  String get stepLabel => step == null ? '--' : 'T$step';

  /// Active signals, e.g. `RO|AI`.
  String get signals => Microcode.describe(controlWord);

  /// One-line caption: transfer and effects.
  String get caption =>
      [if (transfer.isNotEmpty) transfer, ...effects].join(';  ');

  /// Describes the last micro-step [cpu] executed.
  factory StepInfo.of(Cpu cpu) {
    final step = cpu.executedStep;
    final word = cpu.controlWord;

    if (step == null) {
      return StepInfo(
        step: null,
        controlWord: 0,
        purpose: 'ready',
        source: null,
        destinations: const [],
        transfer: '',
        effects: [
          'next step fetches the instruction at ${cpu.mode.hexAddress(cpu.programCounter)}',
        ],
      );
    }

    bool on(ControlWord signal) => signal.isActive(word);
    final mode = cpu.mode;
    final mar = mode.hexAddress(cpu.memoryAddressRegister);

    BusNode? source;
    String? sourceLabel;
    if (on(ControlWord.co)) {
      source = BusNode.programCounter;
      sourceLabel = 'PC';
    } else if (on(ControlWord.ro)) {
      source = BusNode.ram;
      sourceLabel = 'RAM[$mar]';
    } else if (on(ControlWord.io)) {
      source = BusNode.instructionRegister;
      sourceLabel = 'IR operand';
    } else if (on(ControlWord.ao)) {
      source = BusNode.registerA;
      sourceLabel = 'A';
    } else if (on(ControlWord.bo)) {
      source = BusNode.registerB;
      sourceLabel = 'B';
    } else if (on(ControlWord.spo)) {
      source = BusNode.stackPointer;
      sourceLabel = 'SP';
    } else if (on(ControlWord.so)) {
      source = BusNode.alu;
      sourceLabel = aluLabel(word);
    }

    final destinations = <BusNode>[];
    final destinationLabels = <String>[];
    void reads(ControlWord signal, BusNode node, String label) {
      if (on(signal)) {
        destinations.add(node);
        destinationLabels.add(label);
      }
    }

    reads(ControlWord.mi, BusNode.memoryAddress, 'MAR');
    reads(ControlWord.ri, BusNode.ram, 'RAM[$mar]');
    reads(ControlWord.ii, BusNode.instructionRegister, 'IR');
    reads(ControlWord.ai, BusNode.registerA, 'A');
    reads(ControlWord.bi, BusNode.registerB, 'B');
    reads(ControlWord.oi, BusNode.output, 'OUT');
    reads(ControlWord.j, BusNode.programCounter, 'PC');

    final transfer = sourceLabel == null
        ? ''
        : '$sourceLabel = ${_hex8(cpu.bus)} → bus'
              '${destinationLabels.isEmpty ? '' : ' → ${destinationLabels.join(', ')}'}';

    final effects = <String>[
      if (on(ControlWord.ce)) 'PC + 1 → ${mode.hexAddress(cpu.programCounter)}',
      if (on(ControlWord.spInc)) 'SP + 1 → ${_hex8(cpu.stackPointer)}',
      if (on(ControlWord.spDec)) 'SP − 1 → ${_hex8(cpu.stackPointer)}',
      if (on(ControlWord.fi))
        'flags C=${cpu.carryFlag ? 1 : 0} Z=${cpu.zeroFlag ? 1 : 0}',
      if (on(ControlWord.hlt)) 'clock stopped',
      if (word == 0) 'nothing to do this cycle',
    ];

    return StepInfo(
      step: step,
      controlWord: word,
      purpose: _purpose(cpu, step),
      source: source,
      destinations: destinations,
      transfer: transfer,
      effects: effects,
    );
  }

  /// The ALU operation selected by [word], e.g. `A + B` or `A << 1`.
  static String aluLabel(int word) {
    bool on(ControlWord signal) => signal.isActive(word);
    if (on(ControlWord.sl)) return 'A << 1';
    if (on(ControlWord.sr)) return 'A >> 1';
    if (on(ControlWord.an)) return 'A AND B';
    if (on(ControlWord.or)) return 'A OR B';
    if (on(ControlWord.xr)) return 'A XOR B';
    if (on(ControlWord.su)) return 'A − B';
    return 'A + B';
  }

  static String _purpose(Cpu cpu, int step) {
    if (step == 0) return 'fetch: address of next instruction';
    if (step == 1) return 'fetch: load instruction, advance PC';
    final opcode = cpu.currentOpcode;
    final operand = cpu.currentOperand;
    return switch (opcode.operand) {
      OperandKind.none => opcode.mnemonic,
      OperandKind.indexedB => opcode.usage,
      OperandKind.immediate => '${opcode.mnemonic} #$operand',
      OperandKind.address =>
        '${opcode.mnemonic} ${cpu.mode.hexAddress(operand!)}',
    };
  }
}

String _hex8(int v) => '0x${v.toRadixString(16).toUpperCase().padLeft(2, '0')}';
