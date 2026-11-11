import 'control_word.dart';
import 'microcode.dart';
import 'opcode.dart';

/// The 8-bit CPU, independent of any UI.
///
/// Each [tick] is one clock cycle: it looks up the control word for the
/// current micro-step in [Microcode] and applies it. Applying a control
/// word is generic, exactly as on the breadboard: the "out" signals choose
/// which module drives the bus, then every "in" signal latches the bus.
class Cpu {
  static const int ramSize = 16;

  final List<int> ram = List.filled(ramSize, 0);

  /// Program written back into RAM on [reset].
  List<int> get program => _program;
  List<int> _program = const [];

  /// Called with the value latched into the output register (OI).
  void Function(int value)? onOutput;

  // Bus
  int bus = 0;
  bool busActive = false;

  // Registers
  int registerA = 0;
  int registerB = 0;
  int instructionRegister = 0;
  int memoryAddressRegister = 0;
  int programCounter = 0;
  int outputRegister = 0;
  int sumRegister = 0;

  // Flags
  bool carryFlag = false;
  bool zeroFlag = false;
  bool halted = false;

  /// Micro-step (T-state) the next [tick] executes; 0 is T0.
  int microStep = 0;

  /// Control word applied by the last [tick].
  int controlWord = 0;

  /// RAM address of the instruction being executed, latched at T0.
  int instructionAddress = 0;

  Opcode get currentOpcode => Opcode.fromHex((instructionRegister >> 4) & 0xF);

  /// Loads [program] into RAM, keeps it for [reset], and resets the CPU.
  void load(List<int> program) {
    _program = List.unmodifiable(program.take(ramSize));
    reset();
  }

  /// Clears registers and flags, and writes the loaded program back into
  /// RAM, undoing any writes made while it ran.
  void reset() {
    bus = 0;
    busActive = false;
    registerA = 0;
    registerB = 0;
    instructionRegister = 0;
    memoryAddressRegister = 0;
    programCounter = 0;
    outputRegister = 0;
    sumRegister = 0;
    carryFlag = false;
    zeroFlag = false;
    halted = false;
    microStep = 0;
    controlWord = 0;
    instructionAddress = 0;

    ram.fillRange(0, ramSize, 0);
    ram.setRange(0, _program.length, _program);
  }

  /// Edits RAM by hand, as with the DIP switches on the breadboard.
  void writeRam(int address, int value) {
    ram[address & 0xF] = value & 0xFF;
  }

  /// Runs one clock cycle (one micro-step). Does nothing once halted.
  void tick() {
    if (halted) return;

    final step = microStep;
    final opcode = currentOpcode;
    // Step count is taken before the word is applied: flags may change
    // during the instruction, but its length is fixed when it starts.
    final int? stepCount = step < Microcode.fetch.length
        ? null
        : Microcode.stepCount(opcode, carry: carryFlag, zero: zeroFlag);

    if (step == 0) instructionAddress = programCounter;
    controlWord = Microcode.controlWordAt(
      opcode,
      step,
      carry: carryFlag,
      zero: zeroFlag,
    );
    _apply(controlWord);

    microStep = (stepCount != null && step + 1 >= stepCount) ? 0 : step + 1;
  }

  /// Runs the remaining micro-steps of the current instruction; from T0
  /// this is a whole instruction, fetch included.
  void stepInstruction() {
    // The longest instruction takes 5 cycles; the cap guards against a loop.
    for (int i = 0; i < 8; i++) {
      tick();
      if (microStep == 0 || halted) return;
    }
  }

  /// Ticks until the CPU halts or [maxTicks] cycles have run. Returns the
  /// number of cycles run.
  int run({int maxTicks = 100000}) {
    int ticks = 0;
    while (!halted && ticks < maxTicks) {
      tick();
      ticks++;
    }
    return ticks;
  }

  void _apply(int word) {
    bool on(ControlWord signal) => signal.isActive(word);

    // ALU: computed from A and B as they are before this cycle's latches.
    final bool subtract = on(ControlWord.su);
    final int aluResult = subtract
        ? registerA - registerB
        : registerA + registerB;

    // 1. Who drives the bus. At most one "out" signal is active per step.
    busActive = true;
    if (on(ControlWord.co)) {
      bus = programCounter;
    } else if (on(ControlWord.ro)) {
      bus = ram[memoryAddressRegister];
    } else if (on(ControlWord.io)) {
      bus = instructionRegister & 0xF;
    } else if (on(ControlWord.ao)) {
      bus = registerA;
    } else if (on(ControlWord.so)) {
      sumRegister = aluResult & 0xFF;
      bus = sumRegister;
    } else {
      busActive = false; // nothing drives the bus; it keeps its last value
    }

    // 2. Who reads it, on the clock edge.
    if (on(ControlWord.mi)) memoryAddressRegister = bus & 0xF;
    if (on(ControlWord.ri)) ram[memoryAddressRegister] = bus;
    if (on(ControlWord.ii)) instructionRegister = bus;
    if (on(ControlWord.ai)) registerA = bus;
    if (on(ControlWord.bi)) registerB = bus;
    if (on(ControlWord.oi)) {
      outputRegister = bus;
      onOutput?.call(outputRegister);
    }
    if (on(ControlWord.j)) programCounter = bus & 0xF;
    if (on(ControlWord.ce)) programCounter = (programCounter + 1) & 0xF;
    if (on(ControlWord.fi)) {
      // Carry on add is an overflow past 8 bits; on subtract it is a borrow.
      carryFlag = subtract ? aluResult < 0 : aluResult > 0xFF;
      zeroFlag = (aluResult & 0xFF) == 0;
    }
    if (on(ControlWord.hlt)) halted = true;
  }
}
