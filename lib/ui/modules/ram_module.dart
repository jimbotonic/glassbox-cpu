import 'package:flutter/material.dart';

import '../../core/assembler.dart';
import '../../core/cpu_mode.dart';
import '../../core/disassembler.dart';

/// RAM contents, one row per byte. Classic RAM (16 bytes) fits in one
/// view; Extended RAM (256 bytes) is shown one 16-byte page at a time, and
/// the page follows the memory address register unless the user browses
/// to another one.
class RAMModule extends StatefulWidget {
  final List<int> ram;
  final int address;
  final int busValue;
  final bool isInput;
  final bool isOutput;
  final Function(int, int) onEdit;
  final CpuMode mode;

  /// Marked rows (Extended mode): where the program counter and the stack
  /// pointer point.
  final int? programCounter;
  final int? stackPointer;

  const RAMModule({
    super.key,
    required this.ram,
    required this.address,
    required this.busValue,
    required this.isInput,
    required this.isOutput,
    required this.onEdit,
    this.mode = CpuMode.classic,
    this.programCounter,
    this.stackPointer,
  });

  @override
  State<RAMModule> createState() => _RAMModuleState();
}

class _RAMModuleState extends State<RAMModule> {
  static const int _rowsPerPage = 16;

  /// Page chosen with the arrows, or null to follow the MAR.
  int? _browsedPage;

  int get _pageCount => widget.ram.length ~/ _rowsPerPage;
  int get _page => _browsedPage ?? widget.address ~/ _rowsPerPage;

  @override
  void didUpdateWidget(RAMModule old) {
    super.didUpdateWidget(old);
    // Follow the MAR again as soon as it moves, or when the mode changes.
    if (old.address != widget.address || old.mode != widget.mode) {
      _browsedPage = null;
    }
  }

  void _browse(int delta) {
    setState(() => _browsedPage = (_page + delta) % _pageCount);
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final ram = widget.ram;
    final isInput = widget.isInput;
    final isOutput = widget.isOutput;
    final paged = _pageCount > 1;
    final first = paged ? _page * _rowsPerPage : 0;
    final lines = Disassembler.sweep(ram, mode: mode);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RAM',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ram.length} bytes (${mode.addressBits}-bit addressing)',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
          if (paged) ...[
            const SizedBox(height: 6),
            _PageBar(
              first: first,
              last: first + _rowsPerPage - 1,
              mode: mode,
              following: _browsedPage == null,
              onPrevious: () => _browse(-1),
              onNext: () => _browse(1),
            ),
          ],
          SizedBox(height: paged ? 6 : 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(6),
              itemCount: paged ? _rowsPerPage : ram.length,
              itemBuilder: (context, row) {
                final index = first + row;
                final isActive = widget.address == index;
                final tags = [
                  if (widget.programCounter == index) 'PC',
                  if (widget.stackPointer == index) 'SP',
                ];

                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: const Color(0xFF1a1a1a),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _EditRAMDialog(
                          address: index,
                          currentValue: ram[index],
                          mode: mode,
                          onValueChanged: (newValue) =>
                              widget.onEdit(index, newValue),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: paged ? 2.2 : 3.3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isActive ? Colors.red : Colors.grey[800]!,

                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          paged
                              ? mode.hexAddress(index)
                              : 'ADDR: ${mode.hexAddress(index)}',
                          style: TextStyle(
                            color: isActive ? Colors.red : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (paged)
                          SizedBox(
                            width: 30,
                            child: Text(
                              tags.join(' '),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _valueCell(
                                paged,
                                Text(
                                  '0x${ram[index].toRadixString(16).toUpperCase().padLeft(2, '0')}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  lines[index],
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.greenAccent
                                        : Colors.cyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Byte value cell: fixed width beside the PC/SP tags when paged, else
/// half of the row as in the original layout.
Widget _valueCell(bool paged, Widget child) =>
    paged ? SizedBox(width: 34, child: child) : Expanded(child: child);

/// Extended RAM page selector: `< page 0x20-0x2F >`.
class _PageBar extends StatelessWidget {
  final int first;
  final int last;
  final CpuMode mode;
  final bool following;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _PageBar({
    required this.first,
    required this.last,
    required this.mode,
    required this.following,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, String tip, VoidCallback onPressed) =>
        IconButton(
          icon: Icon(icon, size: 16),
          color: Colors.red,
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 22),
          onPressed: onPressed,
        );
    final range = '${mode.hexAddress(first)}-${mode.hexAddress(last)}';
    return Row(
      children: [
        arrow(Icons.chevron_left, 'Previous 16 bytes', onPrevious),
        Expanded(
          child: Text(
            following ? 'page $range  (follows MAR)' : 'page $range',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 10),
          ),
        ),
        arrow(Icons.chevron_right, 'Next 16 bytes', onNext),
      ],
    );
  }
}

class _EditRAMDialog extends StatefulWidget {
  final int address;
  final int currentValue;
  final CpuMode mode;
  final Function(int) onValueChanged;

  const _EditRAMDialog({
    required this.address,
    required this.currentValue,
    required this.mode,
    required this.onValueChanged,
  });

  @override
  State<_EditRAMDialog> createState() => _EditRAMDialogState();
}

class _EditRAMDialogState extends State<_EditRAMDialog> {
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
                  color: Colors.red,
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
                  color: _errorMessage != null ? Colors.redAccent : Colors.red,
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
                  backgroundColor: Colors.red,
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
