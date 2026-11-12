import 'control_word.dart';
import 'cpu_mode.dart';
import 'opcode.dart';

/// The instruction set as data: for each opcode, the control word applied
/// at each micro-step (T-state). This is what the EEPROMs hold in the
/// breadboard computer.
///
/// Every instruction starts with the two [fetch] steps (T0, T1), followed
/// by its own execute steps (T2 onwards). An instruction with nothing to
/// do still spends one empty step, so NOP, HLT and an untaken Classic jump
/// take three cycles.
///
/// The fetch steps are the same in both modes. In Classic mode the operand
/// sits in the low nibble of the instruction register (IO puts it on the
/// bus). In Extended mode it is the byte after the opcode, so an execute
/// step reads it from RAM at the program counter and advances past it:
/// `CO|MI` then `RO|..|CE`.
class Microcode {
  Microcode._();

  static final int _hlt = ControlWord.hlt.hex;
  static final int _mi = ControlWord.mi.hex;
  static final int _ri = ControlWord.ri.hex;
  static final int _ro = ControlWord.ro.hex;
  static final int _io = ControlWord.io.hex;
  static final int _ii = ControlWord.ii.hex;
  static final int _ai = ControlWord.ai.hex;
  static final int _ao = ControlWord.ao.hex;
  static final int _bi = ControlWord.bi.hex;
  static final int _so = ControlWord.so.hex;
  static final int _su = ControlWord.su.hex;
  static final int _oi = ControlWord.oi.hex;
  static final int _ce = ControlWord.ce.hex;
  static final int _co = ControlWord.co.hex;
  static final int _j = ControlWord.j.hex;
  static final int _fi = ControlWord.fi.hex;
  static final int _bo = ControlWord.bo.hex;
  static final int _spo = ControlWord.spo.hex;
  static final int _spInc = ControlWord.spInc.hex;
  static final int _spDec = ControlWord.spDec.hex;
  static final int _an = ControlWord.an.hex;
  static final int _or = ControlWord.or.hex;
  static final int _xr = ControlWord.xr.hex;
  static final int _sl = ControlWord.sl.hex;
  static final int _sr = ControlWord.sr.hex;

  /// T0: MAR <- PC.  T1: IR <- RAM[MAR], PC++.
  static final List<int> fetch = List.unmodifiable([
    _co | _mi,
    _ro | _ii | _ce,
  ]);

  static final List<int> _empty = List.unmodifiable([0]);

  // ---------------------------------------------------------------- Classic

  static final List<int> _classicJump = List.unmodifiable([_io | _j]);

  /// Execute steps of each unconditional Classic instruction.
  static final Map<Opcode, List<int>> _classic = Map.unmodifiable({
    Opcode.nop: _empty,
    Opcode.lda: List<int>.unmodifiable([_io | _mi, _ro | _ai]),
    Opcode.add: List<int>.unmodifiable([_io | _mi, _ro | _bi, _so | _ai | _fi]),
    Opcode.sub: List<int>.unmodifiable([
      _io | _mi,
      _ro | _bi,
      _so | _ai | _su | _fi,
    ]),
    Opcode.sta: List<int>.unmodifiable([_io | _mi, _ao | _ri]),
    Opcode.ldi: List<int>.unmodifiable([_io | _ai]),
    Opcode.jmp: _classicJump,
    Opcode.out: List<int>.unmodifiable([_ao | _oi]),
    Opcode.hlt: List<int>.unmodifiable([_hlt]),
  });

  // --------------------------------------------------------------- Extended

  /// Operand byte address into MAR, then the byte at that address, which
  /// is itself an address, into MAR; PC moves past the operand.
  static List<int> _direct(List<int> then) =>
      List.unmodifiable([_co | _mi, _ro | _mi | _ce, ...then]);

  /// Operand byte (a value) into [into]; PC moves past the operand.
  static List<int> _immediate(int into, [List<int> then = const []]) =>
      List.unmodifiable([_co | _mi, _ro | into | _ce, ...then]);

  /// Operand byte into PC.
  static final List<int> _extendedJump = List.unmodifiable([
    _co | _mi,
    _ro | _j,
  ]);

  /// Untaken jump: step over the operand byte.
  static final List<int> _extendedSkip = List.unmodifiable([_ce]);

  /// `A <- A op RAM[addr]` with flags, B as the ALU's second input.
  static List<int> _aluDirect(int op) =>
      _direct([_ro | _bi, _so | _ai | op | _fi]);

  /// Execute steps of each unconditional Extended instruction.
  static final Map<Opcode, List<int>> _extended = Map.unmodifiable({
    Opcode.nop: _empty,
    Opcode.lda: _direct([_ro | _ai]),
    Opcode.ldb: _direct([_ro | _bi]),
    Opcode.sta: _direct([_ao | _ri]),
    Opcode.ldi: _immediate(_ai),
    Opcode.ldaIndexed: List<int>.unmodifiable([_bo | _mi, _ro | _ai]),
    Opcode.add: _aluDirect(0),
    Opcode.sub: _aluDirect(_su),
    Opcode.and: _aluDirect(_an),
    Opcode.or: _aluDirect(_or),
    Opcode.xor: _aluDirect(_xr),
    // Compare: subtract for the flags only; nothing reads the result.
    Opcode.cmp: _direct([_ro | _bi, _so | _su | _fi]),
    Opcode.adi: _immediate(_bi, [_so | _ai | _fi]),
    Opcode.sbi: _immediate(_bi, [_so | _ai | _su | _fi]),
    Opcode.shl: List<int>.unmodifiable([_so | _ai | _sl | _fi]),
    Opcode.shr: List<int>.unmodifiable([_so | _ai | _sr | _fi]),
    Opcode.jmp: _extendedJump,
    Opcode.out: List<int>.unmodifiable([_ao | _oi]),
    Opcode.hlt: List<int>.unmodifiable([_hlt]),
    // SP points at the next free byte: write there, then move down.
    Opcode.push: List<int>.unmodifiable([_spo | _mi, _ao | _ri | _spDec]),
    // Move up to the last byte written, then read it.
    Opcode.pop: List<int>.unmodifiable([_spInc, _spo | _mi, _ro | _ai]),
    // Push PC, which points at the operand byte, then jump to the operand.
    Opcode.call: List<int>.unmodifiable([
      _spo | _mi,
      _co | _ri | _spDec,
      _co | _mi,
      _ro | _j,
    ]),
    // Pop the saved PC, then step over the CALL's operand byte.
    Opcode.ret: List<int>.unmodifiable([_spInc, _spo | _mi, _ro | _j, _ce]),
  });

  /// Whether the conditional jump [opcode] is taken with these flags, or
  /// null if [opcode] is not a conditional jump. The flag outputs feed the
  /// microcode EEPROM address lines, so the steps depend on them.
  static bool? jumpTaken(
    Opcode opcode, {
    bool carry = false,
    bool zero = false,
  }) => switch (opcode) {
    Opcode.jc => carry,
    Opcode.jz => zero,
    Opcode.jnc => !carry,
    Opcode.jnz => !zero,
    _ => null,
  };

  /// Execute steps (T2 onwards) of [opcode] in [mode].
  static List<int> executeSteps(
    Opcode opcode, {
    CpuMode mode = CpuMode.classic,
    bool carry = false,
    bool zero = false,
  }) {
    final taken = jumpTaken(opcode, carry: carry, zero: zero);
    if (mode == CpuMode.classic) {
      if (taken != null) return taken ? _classicJump : _empty;
      return _classic[opcode] ?? _empty;
    }
    if (taken != null) return taken ? _extendedJump : _extendedSkip;
    return _extended[opcode]!;
  }

  /// Control word of micro-step [step] (0 = T0) of [opcode].
  static int controlWordAt(
    Opcode opcode,
    int step, {
    CpuMode mode = CpuMode.classic,
    bool carry = false,
    bool zero = false,
  }) {
    if (step < fetch.length) return fetch[step];
    final execute = executeSteps(opcode, mode: mode, carry: carry, zero: zero);
    final index = step - fetch.length;
    return index < execute.length ? execute[index] : 0;
  }

  /// Total micro-steps of [opcode], fetch included.
  static int stepCount(
    Opcode opcode, {
    CpuMode mode = CpuMode.classic,
    bool carry = false,
    bool zero = false,
  }) =>
      fetch.length +
      executeSteps(opcode, mode: mode, carry: carry, zero: zero).length;

  /// Most micro-steps any instruction of [mode] takes.
  static int maxStepCount(CpuMode mode) => mode == CpuMode.classic ? 5 : 6;

  /// Active signal mnemonics of [word], e.g. `CO|MI`, or `-` if none.
  static String describe(int word) {
    final names = [
      for (final signal in ControlWord.values)
        if (signal.isActive(word)) signal.controlSignal.mnemonic,
    ];
    return names.isEmpty ? '-' : names.join('|');
  }
}
