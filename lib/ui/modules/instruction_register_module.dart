import 'package:flutter/material.dart';

import '../../core/cpu_mode.dart';
import '../../core/disassembler.dart';

class InstructionRegisterModule extends StatelessWidget {
  final int value;
  final int busValue;
  final bool isInput;
  final bool isOutput;
  final CpuMode mode;

  /// Extended mode: the operand byte that follows the opcode in RAM, or
  /// null if the instruction takes none.
  final int? operand;

  const InstructionRegisterModule({
    super.key,
    required this.value,
    required this.busValue,
    required this.isInput,
    required this.isOutput,
    this.mode = CpuMode.classic,
    this.operand,
  });

  @override
  Widget build(BuildContext context) {
    final bits = value.toRadixString(2).padLeft(8, '0');
    final bitsAsHex = value.toRadixString(16).toUpperCase().padLeft(2, '0');
    // Classic: opcode nibble + operand nibble. Extended: the whole byte is
    // the opcode; the operand, if any, is the next byte in RAM.
    final extended = mode == CpuMode.extended;
    final opcodeBits = extended ? bits : bits.substring(0, 4);
    final operandBits = bits.substring(4, 8);

    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInput || isOutput
              ? Colors.red
              : Colors.red.withValues(alpha: 0.5),
          width: isInput || isOutput ? 3 : 2,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: isInput || isOutput
            ? [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'INS REGISTER',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  if (isInput)
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.green,
                      size: 16,
                    ),
                  if (isOutput)
                    const Icon(Icons.arrow_back, color: Colors.red, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    extended ? 'OPCODE (WHOLE BYTE)' : 'OPCODE',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      for (int i = 0; i < opcodeBits.length; i++)
                        Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: opcodeBits[i] == '1'
                                ? Colors.red
                                : Colors.grey[900],
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: Colors.grey[700]!),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (!extended)
                Column(
                  children: [
                    const Text(
                      'OPERAND',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        for (int i = 0; i < 4; i++)
                          Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: operandBits[i] == '1'
                                  ? Colors.blue
                                  : Colors.grey[900],
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: Colors.grey[700]!),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '0x$bitsAsHex ($value)',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Expanded(
                child: Text(
                  Disassembler.disassemble(value, mode: mode, operand: operand),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
