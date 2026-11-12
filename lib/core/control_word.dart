import 'control_signal.dart';
import 'cpu_mode.dart';

enum ControlWord {
  // ? Bit 0 - Halt
  hlt(ControlSignal.hlt, 0x0001),

  // ? Bit 1 - Memory Address Register In
  mi(ControlSignal.mi, 0x0002),

  // ? Bit 2 - RAM In
  ri(ControlSignal.ri, 0x0004),

  // ? Bit 3 - RAM Out
  ro(ControlSignal.ro, 0x0008),

  // ? Bit 4 - Instruction Register Out (lower 4 bits)
  io(ControlSignal.io, 0x0010),

  // ? Bit 5 - Instruction Register In
  ii(ControlSignal.ii, 0x0020),

  // ? Bit 6 - A Register In
  ai(ControlSignal.ai, 0x0040),

  // ? Bit 7 - A Register Out
  ao(ControlSignal.ao, 0x0080),

  // ? Bit 8 - B Register In
  bi(ControlSignal.bi, 0x0100),

  // ? Bit 9 - Sum Out (ALU output, also called EO)
  so(ControlSignal.so, 0x0200),

  // ? Bit 10 - Subtract mode
  su(ControlSignal.su, 0x0400),

  // ? Bit 11 - Output Register In
  oi(ControlSignal.oi, 0x0800),

  // ? Bit 12 - Program Counter Enable (increment)
  ce(ControlSignal.ce, 0x1000),

  // ? Bit 13 - Program Counter Out
  co(ControlSignal.co, 0x2000),

  // ? Bit 14 - Jump (load Program Counter)
  j(ControlSignal.j, 0x4000),

  // ? Bit 15 - Flags In
  fi(ControlSignal.fi, 0x8000),

  // Extended mode only: a second control EEPROM's worth of signals.

  // ? Bit 16 - B Register Out
  bo(ControlSignal.bo, 0x10000),

  // ? Bit 17 - Stack Pointer Out
  spo(ControlSignal.spo, 0x20000),

  // ? Bit 18 - Stack Pointer increment
  spInc(ControlSignal.spInc, 0x40000),

  // ? Bit 19 - Stack Pointer decrement
  spDec(ControlSignal.spDec, 0x80000),

  // ? Bit 20 - ALU AND
  an(ControlSignal.an, 0x100000),

  // ? Bit 21 - ALU OR
  or(ControlSignal.or, 0x200000),

  // ? Bit 22 - ALU XOR
  xr(ControlSignal.xr, 0x400000),

  // ? Bit 23 - ALU shift left
  sl(ControlSignal.sl, 0x800000),

  // ? Bit 24 - ALU shift right
  sr(ControlSignal.sr, 0x1000000);

  final ControlSignal controlSignal;
  final int hex;

  const ControlWord(this.controlSignal, this.hex);

  bool isActive(int word) => (word & hex) != 0;

  /// The 16 signals of the breadboard computer.
  static final List<ControlWord> classic = List.unmodifiable(
    values.where((w) => w.hex <= 0x8000),
  );

  /// Signals wired up in [mode].
  static List<ControlWord> forMode(CpuMode mode) =>
      mode == CpuMode.classic ? classic : values;

  /// Hex digits needed to show a control word in [mode]: 4 or 7.
  static int hexDigits(CpuMode mode) => mode == CpuMode.classic ? 4 : 7;
}
