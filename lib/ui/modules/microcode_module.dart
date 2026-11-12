import 'package:flutter/material.dart';

import '../../core/control_word.dart';
import '../../core/cpu.dart';
import '../../core/microcode.dart';
import '../../core/opcode.dart';

/// The control logic as a table: the micro-steps of the current
/// instruction with their control words, the step just executed
/// highlighted, and the control signals of that step below (16 in Classic
/// mode, 25 in Extended mode).
///
/// Replaces the separate Control Word and Control Logic panels.
class MicrocodeModule extends StatelessWidget {
  final Cpu cpu;

  const MicrocodeModule({super.key, required this.cpu});

  static const _rowHeight = 19.0;

  @override
  Widget build(BuildContext context) {
    final mode = cpu.mode;
    // Pad to the longest instruction so the panels below never move.
    final maxRows = Microcode.maxStepCount(mode);
    final executed = cpu.executedStep;
    // The instruction register holds the current instruction only once T1
    // has loaded it; at T0 it still holds the previous one.
    final decoded = executed != null && executed >= 1;
    final opcode = cpu.currentOpcode;
    final steps = decoded
        ? [
            ...Microcode.fetch,
            ...Microcode.executeSteps(
              opcode,
              mode: mode,
              carry: cpu.carryFlag,
              zero: cpu.zeroFlag,
            ),
          ]
        : Microcode.fetch;
    final word = cpu.controlWord;
    final hexWord = word
        .toRadixString(16)
        .toUpperCase()
        .padLeft(ControlWord.hexDigits(mode), '0');

    return Container(
      width: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.5),
          width: 2,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MICROCODE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '(CONTROL LOGIC EEPROM)',
                      style: TextStyle(color: Colors.red, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      !decoded
                          ? 'FETCH'
                          : opcode.operand == OperandKind.indexedB
                          ? opcode
                                .usage // LDA [B]
                          : opcode.mnemonic,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '0x$hexWord',
                      style: const TextStyle(color: Colors.cyan, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < steps.length; i++)
            _StepRow(step: i, word: steps[i], isCurrent: i == executed),
          if (!decoded) const _StepRow(step: 2, word: null, isCurrent: false),
          for (int i = steps.length + (decoded ? 0 : 1); i < maxRows; i++)
            const SizedBox(height: _rowHeight + 2),
          const SizedBox(height: 8),
          Wrap(
            spacing: 3,
            runSpacing: 3,
            children: [
              for (final signal in ControlWord.forMode(mode))
                _SignalChip(
                  label: signal.controlSignal.mnemonic,
                  active: signal.isActive(word),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int step;

  /// Control word, or null for the not-yet-decoded execute steps.
  final int? word;
  final bool isCurrent;

  const _StepRow({
    required this.step,
    required this.word,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final undecoded = word == null;
    return Container(
      height: MicrocodeModule._rowHeight,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isCurrent
            ? Colors.green.withValues(alpha: 0.25)
            : Colors.grey[900],
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: isCurrent ? Colors.green : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              undecoded ? 'T$step+' : 'T$step',
              style: TextStyle(
                color: isCurrent ? Colors.green : Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              undecoded
                  ? 'execute steps: decoded once T1 loads the instruction'
                  : Microcode.describe(word!),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: undecoded
                    ? Colors.grey[600]
                    : isCurrent
                    ? Colors.white
                    : Colors.grey[400],
                fontSize: 11,
                fontStyle: undecoded ? FontStyle.italic : FontStyle.normal,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  final String label;
  final bool active;

  const _SignalChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: active ? Colors.green[700] : Colors.grey[900],
        borderRadius: BorderRadius.circular(2),
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : Colors.grey,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
