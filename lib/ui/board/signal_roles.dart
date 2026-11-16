import '../../core/control_word.dart';
import '../../core/cpu_mode.dart';
import '../theme/glass.dart';

/// Control signals grouped by what they do, for the microcode panel.
class SignalGroup {
  final String name;
  final BusRole role;
  final List<ControlWord> signals;

  const SignalGroup(this.name, this.role, this.signals);
}

const List<SignalGroup> _allGroups = [
  SignalGroup('Drive bus', BusRole.drive, [
    ControlWord.co,
    ControlWord.ro,
    ControlWord.io,
    ControlWord.ao,
    ControlWord.bo,
    ControlWord.spo,
    ControlWord.so,
    ControlWord.dout,
  ]),
  SignalGroup('Read bus', BusRole.read, [
    ControlWord.mi,
    ControlWord.ri,
    ControlWord.ii,
    ControlWord.ai,
    ControlWord.bi,
    ControlWord.oi,
    ControlWord.j,
    ControlWord.pi,
    ControlWord.di,
  ]),
  SignalGroup('Counters', BusRole.count, [
    ControlWord.ce,
    ControlWord.spInc,
    ControlWord.spDec,
  ]),
  SignalGroup('ALU', BusRole.count, [
    ControlWord.su,
    ControlWord.an,
    ControlWord.or,
    ControlWord.xr,
    ControlWord.sl,
    ControlWord.sr,
    ControlWord.fi,
  ]),
  SignalGroup('Control', BusRole.count, [ControlWord.hlt]),
];

/// The groups, keeping only the signals wired up in [mode].
List<SignalGroup> signalGroups(CpuMode mode) {
  final wired = ControlWord.forMode(mode).toSet();
  return [
    for (final g in _allGroups)
      SignalGroup(g.name, g.role, g.signals.where(wired.contains).toList()),
  ];
}

/// Role of one signal: drives the bus, reads it, or does something else.
BusRole signalRole(ControlWord signal) {
  for (final g in _allGroups) {
    if (g.signals.contains(signal)) return g.role;
  }
  return BusRole.count;
}

/// Short note on what a control word does, e.g. `RAM → A, PC + 1`.
String wordNote(int word) {
  if (word == 0) return 'nothing';
  bool on(ControlWord s) => s.isActive(word);
  final source = on(ControlWord.co)
      ? 'PC'
      : on(ControlWord.ro)
      ? 'RAM'
      : on(ControlWord.io)
      ? 'IR'
      : on(ControlWord.ao)
      ? 'A'
      : on(ControlWord.bo)
      ? 'B'
      : on(ControlWord.spo)
      ? 'SP'
      : on(ControlWord.so)
      ? 'ALU'
      : on(ControlWord.dout)
      ? 'device'
      : null;
  final readers = [
    if (on(ControlWord.mi)) 'MAR',
    if (on(ControlWord.ri)) 'RAM',
    if (on(ControlWord.ii)) 'IR',
    if (on(ControlWord.ai)) 'A',
    if (on(ControlWord.bi)) 'B',
    if (on(ControlWord.oi)) 'OUT',
    if (on(ControlWord.j)) 'PC',
    if (on(ControlWord.pi)) 'PORT',
    if (on(ControlWord.di)) 'device',
  ];
  return [
    if (source != null)
      '$source → ${readers.isEmpty ? 'bus' : readers.join(', ')}',
    if (on(ControlWord.ce)) 'PC + 1',
    if (on(ControlWord.spInc)) 'SP + 1',
    if (on(ControlWord.spDec)) 'SP − 1',
    if (on(ControlWord.fi)) 'flags',
    if (on(ControlWord.hlt)) 'halt',
  ].join(', ');
}
