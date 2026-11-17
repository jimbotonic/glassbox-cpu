import 'package:flutter/material.dart';

import '../../core/assembler.dart';
import '../../core/control_word.dart';
import '../../core/cpu.dart';
import '../../core/disassembler.dart';
import '../../core/opcode.dart';
import '../../core/step_info.dart';
import '../../l10n/app_strings.dart';
import '../theme/glass.dart';
import 'glass_widgets.dart';
import 'signal_roles.dart';

/// The step just executed, in words: the first thing to read on the board.
class NarrationStrip extends StatelessWidget {
  final Cpu cpu;
  final StepInfo info;
  final AssemblyResult? assembly;

  /// Also show the active control signals.
  final bool detailed;

  const NarrationStrip({
    super.key,
    required this.cpu,
    required this.info,
    required this.assembly,
    required this.detailed,
  });

  String _nextText() {
    final t = tApp;
    if (cpu.halted) return t.haltedNext;
    final mode = cpu.mode;
    if (cpu.atInstructionStart) {
      final pc = cpu.programCounter;
      final opcode = Opcode.decode(cpu.ram[pc], mode);
      final text = Disassembler.disassemble(
        cpu.ram[pc],
        mode: mode,
        operand: opcode.sizeIn(mode) == 2
            ? cpu.ram[(pc + 1) & mode.addressMask]
            : null,
      );
      final line = assembly?.lineForAddress(pc);
      return t.nextFetch(
        text,
        mode.hexAddress(pc),
        line == null ? null : line + 1,
      );
    }
    return t.nextStep(cpu.microStep, info.purpose);
  }

  @override
  Widget build(BuildContext context) {
    final t = tApp;
    final active = [
      for (final s in ControlWord.forMode(cpu.mode))
        if (s.isActive(info.controlWord)) s,
    ];
    final value = info.busValue;
    final char = Glass.char(value);

    const mainStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    );
    final InlineSpan caption = info.sourceLabel == null
        ? TextSpan(text: info.caption.isEmpty ? '—' : info.caption)
        : TextSpan(
            children: [
              TextSpan(
                text: info.sourceLabel,
                style: const TextStyle(color: Glass.driveText),
              ),
              const TextSpan(text: ' = '),
              TextSpan(
                text: Glass.hex2(value),
                style: const TextStyle(
                  fontFamily: Glass.mono,
                  color: Glass.bus,
                ),
              ),
              if (char != null)
                TextSpan(
                  text: ' ($char)',
                  style: const TextStyle(color: Color(0xFFC9B98A)),
                ),
              TextSpan(text: ' → ${t.bus}'),
              if (info.destinationLabels.isNotEmpty) ...[
                const TextSpan(text: ' → '),
                TextSpan(
                  text: info.destinationLabels.join(', '),
                  style: const TextStyle(color: Glass.readText),
                ),
              ],
              for (final effect in info.effects)
                TextSpan(
                  text: ';  $effect',
                  style: const TextStyle(fontSize: 14, color: Glass.busMuted),
                ),
            ],
          );

    return Semantics(
      label: t.lastStep,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
        decoration: BoxDecoration(
          color: Glass.busGround,
          borderRadius: BorderRadius.circular(Glass.radius),
          border: Border.all(color: Glass.busBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: info.step == null ? Glass.border : Glass.bus,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    info.stepLabel,
                    style: TextStyle(
                      fontFamily: Glass.mono,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: info.step == null ? Glass.muted : Glass.ground,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  info.purpose,
                  style: const TextStyle(
                    fontFamily: Glass.mono,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFFF2E3B3),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text.rich(
                    caption,
                    style: mainStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (detailed && active.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Text(
                    t.signals,
                    style: const TextStyle(fontSize: 12, color: Glass.busMuted),
                  ),
                  const SizedBox(width: 6),
                  for (final s in active)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: SignalChip(
                        label: s.controlSignal.mnemonic,
                        role: signalRole(s),
                        active: true,
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Text(
              _nextText(),
              style: const TextStyle(fontSize: 12, color: Glass.busMuted),
            ),
          ],
        ),
      ),
    );
  }
}
