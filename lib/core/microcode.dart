import 'control_word.dart';
import 'opcode.dart';

/// The instruction set as data: for each opcode, the control word applied
/// at each micro-step (T-state). This is what the EEPROMs hold in the
/// breadboard computer.
///
/// Every instruction starts with the two [fetch] steps (T0, T1), followed
/// by its own execute steps (T2 onwards). An instruction with nothing to
/// do still spends one empty step, so NOP, HLT and an untaken jump take
/// three cycles.
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

  /// T0: MAR <- PC.  T1: IR <- RAM[MAR], PC++.
  static final List<int> fetch = List.unmodifiable([
    _co | _mi,
    _ro | _ii | _ce,
  ]);

  static final List<int> _empty = List.unmodifiable([0]);
  static final List<int> _jump = List.unmodifiable([_io | _j]);

  /// Execute steps of each unconditional instruction.
  static final Map<Opcode, List<int>> _execute = Map.unmodifiable({
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
    Opcode.jmp: _jump,
    Opcode.out: List<int>.unmodifiable([_ao | _oi]),
    Opcode.hlt: List<int>.unmodifiable([_hlt]),
  });

  /// Execute steps (T2 onwards) of [opcode]. Conditional jumps depend on the
  /// flags, as the flag outputs feed the microcode EEPROM address lines.
  static List<int> executeSteps(
    Opcode opcode, {
    bool carry = false,
    bool zero = false,
  }) {
    switch (opcode) {
      case Opcode.jc:
        return carry ? _jump : _empty;
      case Opcode.jz:
        return zero ? _jump : _empty;
      default:
        return _execute[opcode]!;
    }
  }

  /// Control word of micro-step [step] (0 = T0) of [opcode].
  static int controlWordAt(
    Opcode opcode,
    int step, {
    bool carry = false,
    bool zero = false,
  }) {
    if (step < fetch.length) return fetch[step];
    final execute = executeSteps(opcode, carry: carry, zero: zero);
    final index = step - fetch.length;
    return index < execute.length ? execute[index] : 0;
  }

  /// Total micro-steps of [opcode], fetch included.
  static int stepCount(
    Opcode opcode, {
    bool carry = false,
    bool zero = false,
  }) => fetch.length + executeSteps(opcode, carry: carry, zero: zero).length;

  /// Active signal mnemonics of [word], e.g. `CO|MI`, or `-` if none.
  static String describe(int word) {
    final names = [
      for (final signal in ControlWord.values)
        if (signal.isActive(word)) signal.controlSignal.mnemonic,
    ];
    return names.isEmpty ? '-' : names.join('|');
  }
}
