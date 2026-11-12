import 'package:flutter/material.dart';

import '../../core/assembler.dart';
import '../../core/cpu_mode.dart';
import '../theme/glass.dart';

/// Edits one RAM byte: an instruction, a hex value or a decimal value.
class RamEditDialog extends StatefulWidget {
  final int address;
  final int currentValue;
  final CpuMode mode;
  final Function(int) onValueChanged;

  const RamEditDialog({
    super.key,
    required this.address,
    required this.currentValue,
    required this.mode,
    required this.onValueChanged,
  });

  @override
  State<RamEditDialog> createState() => RamEditDialogState();
}

class RamEditDialogState extends State<RamEditDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _parseInput(String input) {
    final trimmed = input.trim();

    try {
      // An Extended instruction with an operand is two bytes; one RAM cell
      // takes the opcode byte.
      final machineCode = Assembler(mode: widget.mode).assemble(trimmed);
      if (machineCode.isNotEmpty) {
        return machineCode[0];
      }
    } catch (e) {
      // DO NOTHING!
    }

    if (trimmed.toLowerCase().startsWith('0x')) {
      final hexValue = int.tryParse(trimmed.substring(2), radix: 16);
      if (hexValue != null) return hexValue;
    } else if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed) &&
        trimmed.length <= 2) {
      final hexValue = int.tryParse(trimmed, radix: 16);
      if (hexValue != null) return hexValue;
    }

    final decimalValue = int.tryParse(trimmed);
    if (decimalValue != null) return decimalValue;

    return null;
  }

  void _submitValue() {
    setState(() {
      _errorMessage = null;
    });

    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a value';
      });
      return;
    }

    final parsedValue = _parseInput(input);

    if (parsedValue == null) {
      setState(() {
        _errorMessage =
            'Invalid input. Use instruction, hex (0xFF), or decimal (0-255)';
      });
      return;
    }

    if (parsedValue < 0 || parsedValue > 255) {
      setState(() {
        _errorMessage = 'Value must be between 0 and 255 (got: $parsedValue)';
      });
      return;
    }

    widget.onValueChanged(parsedValue);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EDIT RAM AT ADDRESS ${widget.mode.hexAddress(widget.address)}',
                style: const TextStyle(
                  color: Glass.read,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter instruction, hex, or decimal value',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Examples: LDI #5, 0xFF, 240',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Instruction / Hex / Decimal',
              labelStyle: TextStyle(color: Colors.grey[400]),
              errorText: _errorMessage,
              errorStyle: const TextStyle(color: Colors.redAccent),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(4),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _errorMessage != null ? Colors.redAccent : Glass.read,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.redAccent),
                borderRadius: BorderRadius.circular(4),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onSubmitted: (_) => _submitValue(),
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submitValue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Glass.read,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
