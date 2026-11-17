import 'package:flutter/material.dart';

import '../../core/assembler.dart';
import '../../core/cpu_mode.dart';
import '../../l10n/board_strings.dart';
import '../theme/glass.dart';
import 'glass_widgets.dart';

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
        _errorMessage = tBoard.enterValue;
      });
      return;
    }

    final parsedValue = _parseInput(input);

    if (parsedValue == null) {
      setState(() {
        _errorMessage = tBoard.invalidInput;
      });
      return;
    }

    if (parsedValue < 0 || parsedValue > 255) {
      setState(() {
        _errorMessage = tBoard.valueOutOfRange(parsedValue);
      });
      return;
    }

    widget.onValueChanged(parsedValue);
    Navigator.of(context).pop();
  }

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderSide: BorderSide(color: color, width: width),
        borderRadius: BorderRadius.circular(8),
      );

  @override
  Widget build(BuildContext context) {
    final address = widget.mode.hexAddress(widget.address);
    final current = widget.currentValue;
    final t = tBoard;
    return GlassDialogFrame(
      title: t.editTitle(address),
      note: t.editNote(Glass.hex2(current), current),
      width: 420,
      scrollable: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(
              fontFamily: Glass.mono,
              fontSize: 14,
              color: Glass.text,
            ),
            cursorColor: Glass.bus,
            decoration: InputDecoration(
              labelText: t.inputLabel,
              labelStyle: const TextStyle(color: Glass.muted, fontSize: 13),
              floatingLabelStyle: const TextStyle(color: Glass.driveText),
              hintText: 'LDI #5   0xFF   240',
              hintStyle: const TextStyle(color: Glass.faint),
              filled: true,
              fillColor: Glass.ground,
              errorText: _errorMessage,
              errorMaxLines: 2,
              errorStyle: const TextStyle(color: Glass.led, fontSize: 12),
              enabledBorder: _border(Glass.border),
              focusedBorder: _border(Glass.drive, 2),
              errorBorder: _border(Glass.led),
              focusedErrorBorder: _border(Glass.led, 2),
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
          if (widget.mode == CpuMode.extended) ...[
            const SizedBox(height: 6),
            Text(
              t.operandNote,
              style: const TextStyle(color: Glass.dim, fontSize: 11),
            ),
          ],
        ],
      ),
      actions: [
        GlassButton(label: t.cancel, onPressed: () => Navigator.pop(context)),
        GlassButton(label: t.save, primary: true, onPressed: _submitValue),
      ],
    );
  }
}
