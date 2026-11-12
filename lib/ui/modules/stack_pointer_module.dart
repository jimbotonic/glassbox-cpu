import 'package:flutter/material.dart';

/// Extended mode: the stack pointer, the next free stack byte, and the
/// value on top of the stack (the last one pushed).
class StackPointerModule extends StatelessWidget {
  final int value;
  final List<int> ram;
  final bool isOutput;
  final bool isIncrement;
  final bool isDecrement;
  final double width;

  const StackPointerModule({
    super.key,
    required this.value,
    required this.ram,
    required this.isOutput,
    required this.isIncrement,
    required this.isDecrement,
    this.width = 136,
  });

  static const int _empty = 0xFF;

  @override
  Widget build(BuildContext context) {
    final active = isOutput || isIncrement || isDecrement;
    final depth = _empty - value;
    final hex = value.toRadixString(16).toUpperCase().padLeft(2, '0');
    final top = depth == 0
        ? 'empty'
        : 'top 0x${ram[(value + 1) & 0xFF].toRadixString(16).toUpperCase().padLeft(2, '0')}';

    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? Colors.red : Colors.red.withValues(alpha: 0.5),
          width: active ? 3 : 2,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: active
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
            children: [
              const Expanded(
                child: Text(
                  'STACK PTR',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isOutput)
                const Icon(Icons.arrow_back, color: Colors.red, size: 14),
              if (isIncrement)
                const Icon(Icons.add, color: Colors.yellow, size: 14),
              if (isDecrement)
                const Icon(Icons.remove, color: Colors.yellow, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 7; i >= 0; i--)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ((value >> i) & 1) == 1
                        ? Colors.red
                        : Colors.grey[900],
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '0x$hex  ·  $depth deep',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(top, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        ],
      ),
    );
  }
}
