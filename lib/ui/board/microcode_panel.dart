import 'package:flutter/material.dart';

import '../../core/control_word.dart';
import '../../core/cpu.dart';
import '../../core/cpu_mode.dart';
import '../../core/disassembler.dart';
import '../../core/microcode.dart';
import '../../core/opcode.dart';
import '../theme/glass.dart';
import 'glass_widgets.dart';
import 'signal_roles.dart';

/// The micro-steps of the current instruction, and every control signal
/// grouped by role, lit when active.
class MicrocodePanel extends StatelessWidget {
  final Cpu cpu;

  const MicrocodePanel({super.key, required this.cpu});

  @override
  Widget build(BuildContext context) {
    final mode = cpu.mode;
    final opcode = cpu.currentOpcode;
    final current = cpu.executedStep;
    final word = cpu.controlWord;
    final started = current != null;
    final name = started
        ? Disassembler.disassemble(
            cpu.instructionRegister,
            mode: mode,
            operand: cpu.currentOperand,
          )
        : 'fetch';
    final count = started
        ? Microcode.stepCount(
            opcode,
            mode: mode,
            carry: cpu.carryFlag,
            zero: cpu.zeroFlag,
          )
        : 2;

    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'MICROCODE · $name',
                        style: Glass.panelTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '0x${word.toRadixString(16).toUpperCase().padLeft(ControlWord.hexDigits(mode), '0')}',
                      style: const TextStyle(
                        fontFamily: Glass.mono,
                        fontSize: 11,
                        color: Glass.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (int t = 0; t < Microcode.maxStepCount(mode); t++)
                  _stepRow(t, count, current, opcode, mode),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in signalGroups(mode))
                  if (group.signals.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 72,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Glass.muted,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                for (final s in group.signals)
                                  SignalChip(
                                    label: s.controlSignal.mnemonic,
                                    role: group.role,
                                    active: started && s.isActive(word),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepRow(int t, int count, int? current, Opcode opcode, CpuMode mode) {
    final used = t < count;
    final isCurrent = t == current;
    final stepWord = used
        ? Microcode.controlWordAt(
            opcode,
            t,
            mode: mode,
            carry: cpu.carryFlag,
            zero: cpu.zeroFlag,
          )
        : 0;
    final color = isCurrent
        ? Colors.white
        : used
        ? Glass.textSoft
        : const Color(0xFF4A525C);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFF20283A)
            : used
            ? const Color(0xFF181C22)
            : null,
        borderRadius: BorderRadius.circular(5),
        border: isCurrent ? Border.all(color: const Color(0xFF5B79A8)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              'T$t',
              style: TextStyle(
                fontFamily: Glass.mono,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              used ? Microcode.describe(stepWord).replaceAll('|', ' | ') : '—',
              style: TextStyle(
                fontFamily: Glass.mono,
                fontSize: 12,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              used ? wordNote(stepWord) : 'unused',
              style: TextStyle(
                fontSize: 12,
                color: used ? const Color(0xFFA8B0BA) : const Color(0xFF4A525C),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
