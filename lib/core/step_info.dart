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
  output('OUT');

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
          'next step fetches the instruction at ${_hex4(cpu.programCounter)}',
        ],
      );
    }

    bool on(ControlWord signal) => signal.isActive(word);
    final mar = _hex4(cpu.memoryAddressRegister);

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
    } else if (on(ControlWord.so)) {
      source = BusNode.alu;
      sourceLabel = on(ControlWord.su) ? 'A − B' : 'A + B';
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
      if (on(ControlWord.ce)) 'PC + 1 → ${_hex4(cpu.programCounter)}',
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

  static String _purpose(Cpu cpu, int step) {
    if (step == 0) return 'fetch: address of next instruction';
    if (step == 1) return 'fetch: load instruction, advance PC';
    final opcode = cpu.currentOpcode;
    final operand = cpu.instructionRegister & 0xF;
    if (opcode == Opcode.ldi) return 'LDI #$operand';
    return opcode.requiresOperand
        ? '${opcode.mnemonic} ${_hex4(operand)}'
        : opcode.mnemonic;
  }
}

String _hex4(int v) => '0x${v.toRadixString(16).toUpperCase()}';
String _hex8(int v) => '0x${v.toRadixString(16).toUpperCase().padLeft(2, '0')}';
