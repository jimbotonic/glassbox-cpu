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
              ? 'stack empty · grows down from 0xFF'
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
          _Module(
            name: 'ALU · Σ',
            value: alu.value,
            role: aluRole,
            idle: StepInfo.aluLabel(word),
            note:
                '${StepInfo.aluLabel(word)} = ${alu.value}'
                '${alu.carry ? ' · carry out' : ''}',
          ),
          _FlagsWire(active: fiActive),
          _Flags(cpu: cpu, latched: fiActive),
        ],
      ),
      _Module(
        name: 'OUTPUT REGISTER',
        value: cpu.outputRegister,
        role: _role(null, ControlWord.oi),
        idle: 'port 0',
        note: '${_decoded(cpu.outputRegister)} · drives the display ↓',
      ),
      if (extended) _portModule(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BusHeader(info: info),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _column(left)),
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: Glass.bus.withValues(
                    alpha: info.source == null ? 0.3 : 0.6,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: _column(right)),
            ],
          ),
        ),
        // Wire from the output register down to the display.
        Row(
          children: [
            const Spacer(),
            const SizedBox(width: 4 + 28),
            Expanded(
              child: Center(
                child: Container(
                  width: 3,
                  height: 22,
                  color: Glass.led.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
        _Display(cpu: cpu, outputs: outputs, active: _on(ControlWord.oi)),
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

  Widget _column(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (int i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: _gap),
        children[i],
      ],
    ],
  );
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

  const _Module({
    required this.name,
    required this.value,
    this.bits = 8,
    required this.role,
    required this.idle,
    this.countText,
    required this.note,
    this.stubOnRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final onBus = role == BusRole.drive || role == BusRole.read;
    final stub = Container(
      width: 28,
      height: onBus ? 3 : 1,
      color: switch (role) {
        BusRole.drive => Glass.drive,
        BusRole.read => Glass.read,
        _ => const Color(0xFF39404A),
      },
    );
    final panel = Expanded(
      child: Semantics(
        label: '$name ${Glass.hex2(value)}',
        child: GlassPanel(
          role: role,
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: Glass.panelTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  RoleLabel(role: role, idle: idle, countText: countText),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  LedRow(value: value, bits: bits),
                  const Spacer(),
                  Text(
                    bits <= 4
                        ? '0x${value.toRadixString(16).toUpperCase()}'
                        : Glass.hex2(value),
                    style: Glass.value,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                note,
                style: Glass.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
    return Row(children: stubOnRight ? [panel, stub] : [stub, panel]);
  }
}

/// The FI line from the ALU down to the flags register.
class _FlagsWire extends StatelessWidget {
  final bool active;

  const _FlagsWire({required this.active});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Row(
        children: [
          const SizedBox(width: 28 + 28),
          Container(
            width: 2,
            color: active ? Glass.count : const Color(0xFF6B7480),
          ),
          const SizedBox(width: 8),
          Text(
            active
                ? 'FI · flags latched from the ALU'
                : 'FI · flags in, from the ALU result',
            style: TextStyle(
              fontFamily: Glass.mono,
              fontSize: 11,
              color: active ? Glass.count : const Color(0xFFA8B0BA),
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
        padding: const EdgeInsets.symmetric(vertical: 6),
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
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        borderColor: latched ? Glass.count : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Text('FLAGS', style: Glass.panelTitle)),
                RoleLabel(
                  role: latched ? BusRole.count : BusRole.idle,
                  idle: 'kept',
                  countText: 'LATCHED',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                flag('C', cpu.carryFlag, 'carry'),
                const SizedBox(width: 8),
                flag('Z', cpu.zeroFlag, 'zero'),
              ],
            ),
            const SizedBox(height: 6),
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

  static const int _shown = 24;

  @override
  Widget build(BuildContext context) {
    final value = cpu.outputRegister;
    final char = Glass.char(value);
    final shown = outputs.length > _shown
        ? outputs.sublist(outputs.length - _shown)
        : outputs;
    final printable =
        outputs.isNotEmpty && outputs.every((v) => Glass.char(v) != null);

    return Semantics(
      label: 'Display: $value',
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment.topCenter,
            radius: 1.6,
            colors: [Color(0xFF1E1112), Color(0xFF120B0C)],
          ),
          borderRadius: BorderRadius.circular(14),
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
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DISPLAY',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Color(0xFFFFB3B3),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'what the program shows',
                  style: TextStyle(fontSize: 12, color: Color(0xFFC9A3A3)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0606),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3A1A1A)),
                      ),
                      child: Text(
                        value.toString().padLeft(3, '0'),
                        style: TextStyle(
                          fontFamily: Glass.mono,
                          fontSize: 48,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                          color: Glass.led,
                          shadows: [
                            Shadow(
                              color: Glass.led.withValues(alpha: 0.55),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          char ?? '—',
                          style: const TextStyle(
                            fontFamily: Glass.mono,
                            fontSize: 24,
                            color: Color(0xFFFFD9D9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${Glass.hex2(value)} · '
                          '${value.toRadixString(2).padLeft(8, '0')}',
                          style: const TextStyle(
                            fontFamily: Glass.mono,
                            fontSize: 12,
                            color: Color(0xFFC9A3A3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OUTPUT SO FAR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: Color(0xFFC9A3A3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (outputs.length > _shown)
                        const _OutputChip(text: '…', faded: true),
                      for (int i = 0; i < shown.length; i++)
                        _OutputChip(
                          text: printable
                              ? String.fromCharCode(shown[i])
                              : '${shown[i]}',
                          latest: i == shown.length - 1,
                        ),
                      if (outputs.isEmpty)
                        for (int i = 0; i < 4; i++)
                          const _OutputChip(text: '·', faded: true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    outputs.isEmpty
                        ? 'nothing output yet · OUT copies A here'
                        : '${outputs.length} value${outputs.length == 1 ? '' : 's'}'
                              '${printable ? ' · as text' : ' · as numbers'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFC9A3A3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutputChip extends StatelessWidget {
  final String text;
  final bool latest;
  final bool faded;

  const _OutputChip({
    required this.text,
    this.latest = false,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: faded
            ? const Color(0xFF170D0D)
            : latest
            ? const Color(0xFF2A1414)
            : const Color(0xFF1E1010),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: latest
              ? Glass.led
              : faded
              ? const Color(0xFF4A2626)
              : const Color(0xFF3A1E1E),
        ),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: Glass.mono,
            fontSize: 17,
            color: faded
                ? const Color(0xFF5E3A3A)
                : latest
                ? Colors.white
                : const Color(0xFFFFD9D9),
          ),
        ),
      ),
    );
  }
}
