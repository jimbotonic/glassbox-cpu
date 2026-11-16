import 'package:flutter/material.dart';

import '../../core/assembler.dart';
import '../../core/control_word.dart';
import '../../core/cpu.dart';
import '../../core/cpu_mode.dart';
import '../../core/disassembler.dart';
import '../theme/glass.dart';
import 'glass_widgets.dart';
import 'ram_edit_dialog.dart';

/// Every RAM byte, decoded: instructions as text, data bytes with their
/// label and character from the assembler's source map. The list follows
/// MAR so the byte being accessed stays in view.
class RamPanel extends StatefulWidget {
  final Cpu cpu;
  final AssemblyResult? assembly;
  final void Function(int address, int value) onEdit;

  const RamPanel({
    super.key,
    required this.cpu,
    required this.assembly,
    required this.onEdit,
  });

  @override
  State<RamPanel> createState() => _RamPanelState();
}

class _RamPanelState extends State<RamPanel> {
  static const double _rowHeight = 24;
  final ScrollController _scroll = ScrollController();
  int? _lastMar;

  Cpu get cpu => widget.cpu;

  @override
  void didUpdateWidget(RamPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final mar = cpu.memoryAddressRegister;
    if (mar != _lastMar) {
      _lastMar = mar;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(mar));
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls just enough to show [address], or centres it with [center].
  void _reveal(int address, {bool center = false}) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final top = address * _rowHeight;
    final viewport = position.viewportDimension;
    double? target;
    if (center) {
      target = top - (viewport - _rowHeight) / 2;
    } else if (top < position.pixels) {
      target = top - _rowHeight;
    } else if (top + _rowHeight > position.pixels + viewport) {
      target = top + 2 * _rowHeight - viewport;
    }
    if (target == null) return;
    target = target.clamp(0.0, position.maxScrollExtent);
    if (center) {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(target);
    }
  }

  /// `msg+1` for a data byte after a label, the label itself, or ''.
  String _symbol(int address, AssemblyResult? assembly) {
    if (assembly == null) return '';
    final label = assembly.labels[address];
    if (label != null) return label;
    if (!assembly.dataAddresses.contains(address)) return '';
    for (int a = address - 1; a >= 0; a--) {
      if (!assembly.dataAddresses.contains(a)) return '';
      final l = assembly.labels[a];
      if (l != null) return '$l+${address - a}';
    }
    return '';
  }

  void _edit(int address) {
    showGlassDialog<void>(
      context,
      child: RamEditDialog(
        address: address,
        currentValue: cpu.ram[address],
        mode: cpu.mode,
        onValueChanged: (value) => widget.onEdit(address, value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = cpu.mode;
    final word = cpu.controlWord;
    final stepped = cpu.executedStep != null;
    final role = !stepped
        ? BusRole.idle
        : ControlWord.ro.isActive(word)
        ? BusRole.drive
        : ControlWord.ri.isActive(word)
        ? BusRole.read
        : BusRole.idle;
    final assembly = widget.assembly;
    final decoded = Disassembler.sweep(cpu.ram, mode: mode);
    final mar = cpu.memoryAddressRegister;
    final pc = cpu.programCounter;
    final sp = cpu.stackPointer;
    final extended = mode == CpuMode.extended;

    return GlassPanel(
      role: role,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(child: Text('RAM', style: Glass.panelTitle)),
              RoleLabel(role: role),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${mode.ramSize} bytes · ${mode.addressBits}-bit addresses · tap to edit',
            style: Glass.note,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Go to PC',
                  detail: mode.hexAddress(pc),
                  height: 32,
                  onPressed: () => _reveal(pc, center: true),
                ),
              ),
              if (extended) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: GlassButton(
                    label: 'Go to SP',
                    detail: Glass.hex2(sp),
                    height: 32,
                    onPressed: () => _reveal(sp, center: true),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Glass.ground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                controller: _scroll,
                itemExtent: _rowHeight,
                itemCount: mode.ramSize,
                itemBuilder: (context, a) {
                  final value = cpu.ram[a];
                  final isData = assembly?.dataAddresses.contains(a) ?? false;
                  final view = isData
                      ? (Glass.char(value) ?? '$value')
                      : decoded[a];
                  final isMar = a == mar;
                  final markers = [
                    if (a == pc) 'PC',
                    if (extended && a == sp) 'SP',
                  ].join(' ');
                  return _RamRow(
                    address: mode.hexAddress(a),
                    hex: Glass.hex2(value),
                    view: view,
                    isOperand: !isData && decoded[a].startsWith('  ↳'),
                    isData: isData,
                    symbol: _symbol(a, assembly),
                    markers: markers,
                    highlight: isMar
                        ? (role == BusRole.idle ? null : role)
                        : null,
                    isMar: isMar,
                    isPc: a == pc,
                    onTap: () => _edit(a),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RamRow extends StatelessWidget {
  final String address;
  final String hex;
  final String view;
  final bool isOperand;
  final bool isData;
  final String symbol;
  final String markers;
  final BusRole? highlight;
  final bool isMar;

  /// The program counter points here: an amber tag on the left edge.
  final bool isPc;
  final VoidCallback onTap;

  const _RamRow({
    required this.address,
    required this.hex,
    required this.view,
    required this.isOperand,
    required this.isData,
    required this.symbol,
    required this.markers,
    required this.highlight,
    required this.isMar,
    required this.isPc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (fill, outline) = switch (highlight) {
      BusRole.drive => (Glass.driveRow, Glass.drive),
      BusRole.read => (Glass.readRow, Glass.read),
      _ when isMar => (Glass.raised, Glass.border),
      _ => (null, null),
    };
    return Semantics(
      button: true,
      label: 'RAM $address = $hex, $view',
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(4),
                border: outline == null ? null : Border.all(color: outline),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    child: Text(
                      address,
                      style: Glass.code.copyWith(color: Glass.dim),
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    child: Text(
                      hex,
                      style: Glass.code.copyWith(
                        color: Glass.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      view.trimLeft(),
                      overflow: TextOverflow.ellipsis,
                      style: Glass.code.copyWith(
                        color: isData
                            ? Glass.synData
                            : isOperand
                            ? Glass.faint
                            : Glass.synOp,
                      ),
                    ),
                  ),
                  if (symbol.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        symbol,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Glass.synLabel,
                        ),
                      ),
                    ),
                  if (markers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        markers,
                        style: const TextStyle(
                          fontFamily: Glass.mono,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Glass.bus,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isPc)
            Positioned(
              left: 0,
              top: 3,
              bottom: 3,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: Glass.bus,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
