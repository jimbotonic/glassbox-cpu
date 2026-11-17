import 'package:flutter/material.dart';

import '../../core/assembler.dart';
import '../../core/control_word.dart';
import '../../core/cpu.dart';
import '../../core/cpu_mode.dart';
import '../../core/disassembler.dart';
import '../../core/opcode.dart';
import '../../core/step_info.dart';
import '../theme/glass.dart';
import 'glass_widgets.dart';
import 'grow_column.dart';

/// The modules around the bus: who drives it (blue), who reads it
/// (orange), the flags hanging off the ALU, and the display fed by the
/// output register.
class Datapath extends StatelessWidget {
  final Cpu cpu;
  final StepInfo info;
  final AssemblyResult? assembly;

  /// Every value written to the output register since the last reset.
  final List<int> outputs;

  const Datapath({
    super.key,
    required this.cpu,
    required this.info,
    required this.assembly,
    required this.outputs,
  });

  static const double _gap = 8;

  /// Width of the stub from a card to the bus line, and of the bus line.
  static const double _stub = 28;
  static const double _spine = 4;

  /// Where the output register meets the bus, and where its wire to the
  /// display leaves, measured up from the register's bottom edge. The bus
  /// line ends at the first, so the wire passes under its end.
  static const double _outBusFromBottom = 42;

  /// Most height a card gains when the board has room to spare.
  static const double _maxGrow = 14;
  static const double _outWireFromBottom = 17;

  bool _on(ControlWord s) => s.isActive(cpu.controlWord);

  BusRole _role(ControlWord? drive, ControlWord? read, [ControlWord? count]) {
    if (info.step == null) return BusRole.idle;
    if (drive != null && _on(drive)) return BusRole.drive;
    if (read != null && _on(read)) return BusRole.read;
    if (count != null && _on(count)) return BusRole.count;
    return BusRole.idle;
  }

  /// `msg+1` for an address inside labelled data, the label itself, or null.
  String? _symbolAt(int address) {
    final labels = assembly?.labels;
    if (labels == null || labels.isEmpty) return null;
    if (labels[address] != null) return labels[address];
    for (int a = address - 1; a >= 0 && address - a < 64; a--) {
      if (!(assembly!.dataAddresses.contains(a))) return null;
      final label = labels[a];
      if (label != null) return '$label+${address - a}';
    }
    return null;
  }

  String _decoded(int value) {
    final char = Glass.char(value);
    return '$value${char == null ? '' : ' · $char'}';
  }

  String _instructionText(int address) {
    final mode = cpu.mode;
    final byte = cpu.ram[address & mode.addressMask];
    final opcode = Opcode.decode(byte, mode);
    return Disassembler.disassemble(
      byte,
      mode: mode,
      operand: opcode.sizeIn(mode) == 2
          ? cpu.ram[(address + 1) & mode.addressMask]
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = cpu.mode;
    final extended = mode == CpuMode.extended;
    final mar = cpu.memoryAddressRegister;
    final marHex = mode.hexAddress(mar);
    final marSymbol = _symbolAt(mar);
    final ramValue = cpu.ram[mar];
    final alu = cpu.aluResult();
    final word = cpu.controlWord;
    final sp = cpu.stackPointer;
    final stackDepth = Cpu.initialStackPointer - sp;
    final isData = assembly?.dataAddresses.contains(mar) ?? false;

    final ir = cpu.instructionRegister;
    final irNote = info.step == null && cpu.programCounter == 0 && ir == 0
        ? 'empty until the first fetch'
        : extended
        ? '${Disassembler.disassemble(ir, mode: mode, operand: cpu.currentOperand)}'
              '${cpu.currentOpcode.sizeIn(mode) == 2 ? ' · operand at ${mode.hexAddress(cpu.instructionAddress + 1)}' : ''}'
        : '${Disassembler.disassemble(ir, mode: mode)} · '
              'opcode ${ir >> 4} · operand ${ir & 0xF}';

    final left = <Widget>[
      _Module(
        name: 'PROGRAM COUNTER',
        value: cpu.programCounter,
        bits: mode.addressBits,
        role: _role(ControlWord.co, ControlWord.j, ControlWord.ce),
        idle: '${mode.addressBits}-bit',
        countText: '+1',
        note: cpu.halted
            ? 'stopped'
            : 'next: ${_instructionText(cpu.programCounter)}',
        stubOnRight: true,
      ),
      _Module(
        name: 'MEMORY ADDRESS',
        value: mar,
        bits: mode.addressBits,
        role: _role(null, ControlWord.mi),
        idle: 'MAR',
        note:
            'selects RAM[$marHex]'
            '${marSymbol == null ? '' : ' · $marSymbol'}',
        stubOnRight: true,
      ),
      _Module(
        name: 'RAM [MAR]',
        value: ramValue,
        role: _role(ControlWord.ro, ControlWord.ri),
        idle: 'port',
        note: isData
            ? "RAM[$marHex] = ${_decoded(ramValue)}"
            : 'RAM[$marHex] = ${Glass.hex2(ramValue)}',
        stubOnRight: true,
      ),
      _Module(
        name: 'INSTRUCTION',
        value: ir,
        role: _role(ControlWord.io, ControlWord.ii),
        idle: 'IR',
        note: irNote,
        stubOnRight: true,
      ),
      if (extended)
        _Module(
          name: 'STACK POINTER',
          value: sp,
          role: _role(ControlWord.spo, null) == BusRole.drive
              ? BusRole.drive
              : (info.step != null &&
                    (_on(ControlWord.spInc) || _on(ControlWord.spDec)))
              ? BusRole.count
              : BusRole.idle,
          idle: '8-bit',
          countText: _on(ControlWord.spInc) ? '+1' : '−1',
          note: stackDepth == 0
              ? 'empty · grows down'
              : '$stackDepth byte${stackDepth == 1 ? '' : 's'} on the stack',
          stubOnRight: true,
        ),
    ];

    final aluRole = _role(ControlWord.so, null);
    final fiActive = info.step != null && _on(ControlWord.fi);

    final right = <Widget>[
      _Module(
        name: 'A REGISTER',
        value: cpu.registerA,
        role: _role(ControlWord.ao, ControlWord.ai),
        idle: 'accumulator',
        note: _decoded(cpu.registerA),
      ),
      _Module(
        name: 'B REGISTER',
        value: cpu.registerB,
        role: _role(ControlWord.bo, ControlWord.bi),
        idle: extended ? 'operand · index' : 'operand',
        note: _decoded(cpu.registerB),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Module(
              name: 'ALU · Σ',
              value: alu.value,
              role: aluRole,
              idle: StepInfo.aluLabel(word),
              note:
                  '${StepInfo.aluLabel(word)} = ${alu.value}'
                  '${alu.carry ? ' · carry out' : ''}',
            ),
          ),
          _FlagsWire(active: fiActive),
          Expanded(
            child: _Flags(cpu: cpu, latched: fiActive),
          ),
        ],
      ),
      if (extended) _portModule(),
      // Last on the right, level with the display's foot: it meets the bus
      // high on its left side, and its wire to the display leaves lower down.
      _Module(
        name: 'OUTPUT REGISTER',
        value: cpu.outputRegister,
        role: _role(null, ControlWord.oi),
        idle: 'port 0',
        note: '${_decoded(cpu.outputRegister)} · drives the display',
        stubFromBottom: _outBusFromBottom,
      ),
    ];
    final outActive = _on(ControlWord.oi);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BusHeader(info: info),
        const SizedBox(height: 10),
        // Both columns stretch to the taller one; the shorter spreads its
        // gaps. The display ends the left column and the output register the
        // right, bottoms level, so the red wire runs straight across from the
        // register's left side, under the end of the bus line, to the display.
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _spread([
                  ...left,
                  Padding(
                    padding: const EdgeInsets.only(right: _stub),
                    child: _Display(
                      cpu: cpu,
                      outputs: outputs,
                      active: outActive,
                    ),
                  ),
                ]),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: _spine,
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Glass.bus.withValues(
                                      alpha: info.source == null ? 0.3 : 0.6,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: _outBusFromBottom - 1.5),
                            ],
                          ),
                        ),
                        Expanded(child: _spread(right)),
                      ],
                    ),
                    Positioned(
                      left: -_stub,
                      width: _stub + _spine + _stub,
                      bottom: _outWireFromBottom - 6,
                      height: 12,
                      child: CustomPaint(
                        painter: _DisplayWire(active: outActive),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The port register, and the device it selects: blue when the device
  /// drives the bus (IN), orange when the register or the device reads it.
  Widget _portModule() {
    final port = cpu.portRegister;
    final stepped = info.step != null;
    final devIn = stepped && _on(ControlWord.di);
    final devOut = stepped && _on(ControlWord.dout);
    final role = devOut
        ? BusRole.drive
        : (stepped && _on(ControlWord.pi)) || devIn
        ? BusRole.read
        : BusRole.idle;
    final name = cpu.io.portName(port);
    final note = devIn
        ? '$name ← ${Glass.hex2(cpu.bus)}'
        : devOut
        ? '$name → bus: ${Glass.hex2(cpu.bus)}'
        : 'port $port · $name';
    return _Module(
      name: 'I/O PORT',
      value: port,
      role: role,
      idle: 'PI · DI · DO',
      note: note,
    );
  }

  /// A column of cards that grow a little, then spread, to fill the height
  /// the datapath is given.
  Widget _spread(List<Widget> children) =>
      GrowColumn(gap: _gap, maxGrow: _maxGrow, children: children);
}

/// The output register's wire to the display: straight left from the
/// register's side, across the stub gaps and under the end of the bus line,
/// ending in an arrow at the display's right edge.
class _DisplayWire extends CustomPainter {
  final bool active;

  const _DisplayWire({required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    const head = 6.0;
    final color = Glass.led.withValues(alpha: active ? 1 : 0.7);
    canvas.drawLine(
      Offset(size.width, y),
      Offset(head, y),
      Paint()
        ..color = color
        ..strokeWidth = active ? 3 : 2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, y)
        ..lineTo(head, y - 4)
        ..lineTo(head, y + 4)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_DisplayWire old) => old.active != active;
}

/// `BUS 0x45 · 69 · 'E'   RAM drives · A reads`
class _BusHeader extends StatelessWidget {
  final StepInfo info;

  const _BusHeader({required this.info});

  @override
  Widget build(BuildContext context) {
    final idle = info.source == null;
    final value = info.busValue;
    final char = Glass.char(value);
    final who = idle
        ? 'nothing drives the bus this step'
        : '${info.source!.label} drives'
              '${info.destinations.isEmpty ? '' : ' · ${info.destinations.map((d) => d.label).join(', ')} read${info.destinations.length == 1 ? 's' : ''}'}';
    return Row(
      children: [
        const Expanded(child: Divider(color: Glass.border, height: 1)),
        const SizedBox(width: 10),
        Text(
          'BUS',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            fontSize: 12,
            color: idle ? Glass.dim : Glass.bus,
          ),
        ),
        const SizedBox(width: 10),
        if (!idle) ...[
          Text(
            '${Glass.hex2(value)} · $value${char == null ? '' : ' · $char'}',
            style: const TextStyle(
              fontFamily: Glass.mono,
              fontSize: 14,
              color: Glass.bus,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Text(who, style: const TextStyle(fontSize: 12, color: Glass.busMuted)),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Glass.border, height: 1)),
      ],
    );
  }
}

/// A register-like module: name, role, bit LEDs, hex value and a note,
/// with a stub toward the bus spine.
class _Module extends StatelessWidget {
  final String name;
  final int value;
  final int bits;
  final BusRole role;
  final String idle;
  final String? countText;
  final String note;
  final bool stubOnRight;

  /// Height of the bus stub above the card's bottom edge; null centres it.
  final double? stubFromBottom;

  const _Module({
    required this.name,
    required this.value,
    this.bits = 8,
    required this.role,
    required this.idle,
    this.countText,
    required this.note,
    this.stubOnRight = false,
    this.stubFromBottom,
  });

  @override
  Widget build(BuildContext context) {
    final onBus = role == BusRole.drive || role == BusRole.read;
    final stubHeight = onBus ? 3.0 : 1.0;
    final stub = Container(
      width: 28,
      height: stubHeight,
      color: switch (role) {
        BusRole.drive => Glass.drive,
        BusRole.read => Glass.read,
        _ => const Color(0xFF39404A),
      },
    );
    final panel = Expanded(
      child: Semantics(
        label: '$name ${Glass.hex2(value)}',
        // Two rows: name, role and value; then the bit LEDs and the note.
        child: GlassPanel(
          role: role,
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // The name always shows in full; the role gives way.
                  Text(name, style: Glass.panelTitle, maxLines: 1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RoleLabel(
                      role: role,
                      idle: idle,
                      countText: countText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    bits <= 4
                        ? '0x${value.toRadixString(16).toUpperCase()}'
                        : Glass.hex2(value),
                    style: Glass.value,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  LedRow(value: value, bits: bits),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Tooltip(
                      message: note,
                      waitDuration: const Duration(milliseconds: 600),
                      child: Text(
                        note,
                        style: Glass.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    final from = stubFromBottom;
    if (from != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: from - stubHeight / 2),
            child: Align(alignment: Alignment.bottomCenter, child: stub),
          ),
          panel,
        ],
      );
    }
    final centred = Center(child: stub);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: stubOnRight ? [panel, centred] : [centred, panel],
    );
  }
}

/// The FI line from the ALU down to the flags register.
class _FlagsWire extends StatelessWidget {
  final bool active;

  const _FlagsWire({required this.active});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          const SizedBox(width: 28 + 28),
          Container(
            width: 2,
            color: active ? Glass.count : const Color(0xFF6B7480),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              active
                  ? 'FI · flags latched from the ALU'
                  : 'FI · flags in, from the ALU result',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: Glass.mono,
                fontSize: 11,
                color: active ? Glass.count : const Color(0xFFA8B0BA),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Flags extends StatelessWidget {
  final Cpu cpu;
  final bool latched;

  const _Flags({required this.cpu, required this.latched});

  @override
  Widget build(BuildContext context) {
    Widget flag(String letter, bool set, String name) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: set ? const Color(0xFF2A1414) : Glass.ground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: set ? Glass.led : Glass.border),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$letter ${set ? 1 : 0}',
                style: const TextStyle(
                  fontFamily: Glass.mono,
                  fontWeight: FontWeight.w700,
                  color: Glass.text,
                ),
              ),
              TextSpan(
                text: '  $name',
                style: const TextStyle(color: Glass.muted),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 28),
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(14, 7, 14, 8),
        borderColor: latched ? Glass.count : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Text('FLAGS', style: Glass.panelTitle),
                const SizedBox(width: 12),
                flag('C', cpu.carryFlag, 'carry'),
                const SizedBox(width: 8),
                flag('Z', cpu.zeroFlag, 'zero'),
                const SizedBox(width: 12),
                RoleLabel(
                  role: latched ? BusRole.count : BusRole.idle,
                  idle: 'kept',
                  countText: 'LATCHED',
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              cpu.mode == CpuMode.classic
                  ? '→ microcode: decides JC, JZ'
                  : '→ microcode: decides JC, JZ, JNC, JNZ',
              style: const TextStyle(fontSize: 11, color: Glass.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the person running the program sees: the output register as a
/// big decimal number, and every value output so far.
class _Display extends StatelessWidget {
  final Cpu cpu;
  final List<int> outputs;
  final bool active;

  const _Display({
    required this.cpu,
    required this.outputs,
    required this.active,
  });

  static const _pink = Color(0xFFFFB3B3);
  static const _rose = Color(0xFFC9A3A3);
  static const _shell = Color(0xFFFFD9D9);

  /// Most numbers the history lists; two lines hold fewer, and the oldest
  /// give way to an ellipsis.
  static const int _kept = 48;

  /// Characters of text kept: the latest end must stay in view, so no more
  /// than two lines hold even at the narrowest board.
  static const int _keptText = 20;

  @override
  Widget build(BuildContext context) {
    final value = cpu.outputRegister;
    final printable =
        outputs.isNotEmpty && outputs.every((v) => Glass.char(v) != null);
    final count = outputs.isEmpty
        ? null
        : '${outputs.length} value${outputs.length == 1 ? '' : 's'}';

    return Semantics(
      label: 'Display: $value',
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment.topCenter,
            radius: 1.6,
            colors: [Color(0xFF1E1112), Color(0xFF120B0C)],
          ),
          borderRadius: BorderRadius.circular(Glass.radius),
          border: Border.all(
            color: active ? Glass.read : const Color(0xFF6A2B2B),
          ),
          boxShadow: [
            BoxShadow(
              color: Glass.led.withValues(alpha: 0.12),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Text(
                  'DISPLAY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: _pink,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'port 0',
                  style: TextStyle(fontSize: 11, color: _rose),
                ),
                const Spacer(),
                if (count != null)
                  Text(
                    count,
                    style: const TextStyle(fontSize: 11, color: _rose),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0606),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF3A1A1A)),
                  ),
                  child: Text(
                    value.toString().padLeft(3, '0'),
                    style: TextStyle(
                      fontFamily: Glass.mono,
                      fontSize: 40,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: Glass.led,
                      shadows: [
                        Shadow(
                          color: Glass.led.withValues(alpha: 0.55),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: _history(printable)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Everything output so far, beside the number: text as it was written
  /// (its latest end kept), numbers newest first.
  Widget _history(bool printable) {
    if (outputs.isEmpty) {
      return const Text(
        'nothing output yet\nOUT copies A here',
        style: TextStyle(fontSize: 11, height: 1.5, color: _rose),
      );
    }
    const valueStyle = TextStyle(
      fontFamily: Glass.mono,
      fontSize: 14,
      height: 1.45,
      color: _shell,
    );
    const latestStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );

    final InlineSpan values;
    if (printable) {
      final cut = outputs.length > _keptText;
      final tail = cut ? outputs.sublist(outputs.length - _keptText) : outputs;
      values = TextSpan(
        children: [
          if (cut) const TextSpan(text: '…'),
          TextSpan(text: String.fromCharCodes(tail.take(tail.length - 1))),
          TextSpan(text: String.fromCharCode(tail.last), style: latestStyle),
        ],
      );
    } else {
      final newest = outputs.reversed.take(_kept).toList();
      values = TextSpan(
        children: [
          TextSpan(text: '${newest.first}', style: latestStyle),
          for (final v in newest.skip(1)) TextSpan(text: '  $v'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          printable ? 'as text' : 'newest first',
          style: const TextStyle(fontSize: 11, color: _rose),
        ),
        Text.rich(
          values,
          style: valueStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
