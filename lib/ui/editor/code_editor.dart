import 'package:flutter/material.dart';

import '../../core/assembler.dart';
import '../../core/builtin_program_list.dart';
import 'assembly_text_editing_controller.dart';
import 'builtin_program_browser_dialog.dart';
import 'instruction_set_dialog.dart';

class ProgramEditor extends StatefulWidget {
  final Function(List<int> program, bool hasError) onAssemble;
  final String? initialProgram;

  /// RAM address of the instruction being executed; its source line is
  /// highlighted while the editor text matches the assembled program.
  final int? currentAddress;

  /// Addresses of the instructions on breakpoint lines, reported whenever
  /// breakpoints or the assembled program change.
  final ValueChanged<Set<int>>? onBreakpointsChanged;

  /// Address of the instruction on the cursor line, or null, reported when
  /// it changes; used for run-to-cursor.
  final ValueChanged<int?>? onCursorAddressChanged;

  /// Extra buttons shown in the header, next to the status icon.
  final List<Widget> headerActions;

  const ProgramEditor({
    super.key,
    required this.onAssemble,
    this.initialProgram,
    this.currentAddress,
    this.onBreakpointsChanged,
    this.onCursorAddressChanged,
    this.headerActions = const [],
  });

  @override
  State<ProgramEditor> createState() => _ProgramEditorState();
}

class _ProgramEditorState extends State<ProgramEditor> {
  static const _programs = BuiltinProgramList.all;
  static final _categories = BuiltinProgramList.getCategories();
  static final _assembler = Assembler();

  late final TextEditingController _errorMessageController;
  late final AssemblyTextEditingController _editorController;

  late final ScrollController _scrollController;
  late final ScrollController _lineNumberScrollController;

  bool _isLogTypeInfo = false;
  bool _isLogTypeError = false;

  bool isAssembled = false;
  int _lineCount = 1;

  // Source map of the last successful assembly (address -> source line)
  AssemblyResult? _assembly;

  /// Source line to highlight, or null when the text no longer matches the
  /// assembled program.
  int? get _highlightedLine {
    final address = widget.currentAddress;
    if (!isAssembled || _assembly == null || address == null) return null;
    return _assembly!.lineForAddress(address);
  }

  // 0-based line of the last assembler error, shown in red in the gutter
  int? _errorLine;

  // 0-based lines with a breakpoint
  final Set<int> _breakpointLines = {};
  int? _reportedCursorAddress;

  /// Instruction address for [line] in the current assembly, or null.
  int? _addressForLine(int line) =>
      isAssembled ? _assembly?.addressForLine(line) : null;

  void _reportBreakpoints() {
    widget.onBreakpointsChanged?.call({
      for (final line in _breakpointLines) ?_addressForLine(line),
    });
  }

  void _reportCursor() {
    final offset = _editorController.selection.baseOffset;
    final text = _editorController.text;
    int? address;
    if (offset >= 0 && offset <= text.length) {
      final line = '\n'.allMatches(text.substring(0, offset)).length;
      address = _addressForLine(line);
    }
    if (address != _reportedCursorAddress) {
      _reportedCursorAddress = address;
      // Controller listeners can fire while the tree builds; report after.
      Future.microtask(() {
        if (mounted) widget.onCursorAddressChanged?.call(address);
      });
    }
  }

  /// Whether [line] holds an instruction: not blank, comment, label-only,
  /// or a directive such as `.db`.
  bool _isInstructionLine(int line) {
    final lines = _editorController.text.split('\n');
    if (line >= lines.length) return false;
    var code = lines[line];
    final comment = findCommentStart(code);
    if (comment >= 0) code = code.substring(0, comment);
    code = code.replaceFirst(RegExp(r'^\s*[A-Za-z_]\w*\s*:'), '').trim();
    return code.isNotEmpty && !code.startsWith('.');
  }

  /// Address and bytes assembled from [line], for the listing column.
  ({String text, String tooltip, bool isData})? _listingFor(int line) {
    final assembly = _assembly;
    if (!isAssembled || assembly == null) return null;
    final addresses = assembly.addressesForLine(line);
    if (addresses.isEmpty) return null;

    String hex(int v, int width) =>
        v.toRadixString(16).toUpperCase().padLeft(width, '0');
    final bytes = [for (final a in addresses) hex(assembly.machineCode[a], 2)];
    final first = addresses.first;
    final range = addresses.length == 1
        ? '0x${hex(first, 1)}'
        : '0x${hex(first, 1)}-0x${hex(addresses.last, 1)}';
    return (
      text: '${hex(first, 1)} ${bytes.first}${bytes.length > 1 ? '+' : ''}',
      tooltip: '$range: ${bytes.join(' ')}',
      isData: assembly.dataAddresses.contains(first),
    );
  }

  static const double _listingWidth = 46;

  /// Listing column: address and first byte assembled from [line], e.g.
  /// `3 4F`, with a `+` when a `.db` line fills several bytes.
  Widget _listingCell(int line) {
    final listing = _listingFor(line);
    final cell = SizedBox(
      width: _listingWidth,
      child: listing == null
          ? null
          : Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: listing.text.substring(0, listing.text.indexOf(' ')),
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  TextSpan(
                    text: listing.text.substring(listing.text.indexOf(' ')),
                    style: TextStyle(
                      color: listing.isData
                          ? AssemblyTextEditingController.stringColor
                          : Colors.teal[200],
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, height: 1.5 * 13 / 11),
            ),
    );
    return listing == null
        ? cell
        : Tooltip(
            message: listing.tooltip,
            waitDuration: const Duration(milliseconds: 400),
            child: cell,
          );
  }

  void _toggleBreakpoint(int line) {
    if (!_isInstructionLine(line) && !_breakpointLines.contains(line)) return;
    setState(() {
      if (!_breakpointLines.remove(line)) _breakpointLines.add(line);
    });
    _reportBreakpoints();
  }

  @override
  void initState() {
    super.initState();
    _editorController = AssemblyTextEditingController(
      text: widget.initialProgram ?? '',
    );
    _editorController.addListener(_reportCursor);
    _errorMessageController = TextEditingController(
      text: '[NORMAL] Initialized!',
    );
    _scrollController = ScrollController();
    _lineNumberScrollController = ScrollController();
    _scrollController.addListener(_syncLineNumberScroll);
    _updateLineCount();
  }

  void _updateLineCount() {
    setState(() {
      _lineCount = '\n'.allMatches(_editorController.text).length + 1;
    });
  }

  void _syncLineNumberScroll() {
    if (_lineNumberScrollController.hasClients &&
        _scrollController.hasClients) {
      _lineNumberScrollController.jumpTo(_scrollController.offset);
    }
  }

  void _setLogTypeNormal() {
    setState(() {
      _isLogTypeInfo = false;
      _isLogTypeError = false;
    });
  }

  void _setLogTypeInfo() {
    setState(() {
      _isLogTypeInfo = true;
      _isLogTypeError = false;
    });
  }

  void _setLogTypeError() {
    setState(() {
      _isLogTypeInfo = false;
      _isLogTypeError = true;
    });
  }

  @override
  void dispose() {
    _editorController.dispose();
    _errorMessageController.dispose();
    _scrollController.dispose();
    _lineNumberScrollController.dispose();
    super.dispose();
  }

  void _assembleProgram() {
    try {
      final assembly = _assembler.assembleWithSourceMap(_editorController.text);
      final program = assembly.machineCode;
      setState(() {
        isAssembled = true;
        _assembly = assembly;
        _errorLine = null;
      });
      _errorMessageController.text =
          '[INFO] Assembled successfully!\n[INFO] See RAM\'s content in the CPU Board.';
      _setLogTypeInfo();
      widget.onAssemble(program, false);
      _reportBreakpoints();
      _reportCursor();
    } catch (e) {
      setState(() {
        isAssembled = false;
        final line = e is AssemblerError ? e.line : null;
        _errorLine = line == null ? null : line - 1;
      });
      _errorMessageController.text = '[ERROR] ${e.toString()}';
      _setLogTypeError();
      widget.onAssemble([], true);
      _reportBreakpoints();
      _reportCursor();
    }
  }

  void _openProgramBrowserDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: BuiltinProgramBrowserDialog(
          programs: _programs,
          categories: _categories,
          onProgramSelected: (program) {
            setState(() {
              isAssembled = false;
              _errorLine = null;
              _breakpointLines.clear();
            });
            _editorController.text = program.code;
            _updateLineCount();
            _reportBreakpoints();
            _errorMessageController.text =
                '[NORMAL] Program loaded successfully!';
            _setLogTypeNormal();
          },
        ),
      ),
    );
  }

  void _openInstructionSetDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: const InstructionSetDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const hintText =
        'Enter assembly code here...\n\n'
        'Example:\n'
        '.equ STEP 1     ; named constant\n'
        'loop: LDA n     ; label\n'
        '      OUT\n'
        '      SUB step\n'
        '      STA n\n'
        '      JZ  done\n'
        '      JMP loop\n'
        'done: HLT\n'
        'n:    .db 5     ; data byte\n'
        'step: .db STEP';

    final highlightedLine = _highlightedLine;
    // Picked up by buildTextSpan when the TextField below rebuilds.
    _editorController.highlightedLine = highlightedLine;

    return Container(
      width: 460,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isLogTypeError
              ? Colors.red
              : isAssembled
              ? Colors.green
              : Colors.blue.withValues(alpha: 0.5),
          strokeAlign: BorderSide.strokeAlignOutside,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROGRAM EDITOR (ASSEMBLER)',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Generate machine code from assembly code',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  ...widget.headerActions,
                  const SizedBox(width: 6),
                  Icon(
                    _isLogTypeError
                        ? Icons.error
                        : isAssembled
                        ? Icons.check_circle
                        : Icons.code,
                    color: _isLogTypeError
                        ? Colors.red
                        : isAssembled
                        ? Colors.green
                        : Colors.blue,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 455,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: (_lineCount > 99 ? 44 : 34) + _listingWidth,
                  height: 455,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    border: Border(right: BorderSide(color: Colors.grey[800]!)),
                  ),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      controller: _lineNumberScrollController,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(
                          _lineCount,
                          (index) => GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _toggleBreakpoint(index),
                            child: Tooltip(
                              message: 'Toggle breakpoint',
                              waitDuration: const Duration(seconds: 1),
                              child: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _breakpointLines.contains(index)
                                          ? Colors.red
                                          : Colors.transparent,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${index + 1}',
                                      textAlign: TextAlign.right,
                                      style: index == _errorLine
                                          ? const TextStyle(
                                              fontSize: 13,
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              height: 1.5,
                                            )
                                          : index == highlightedLine
                                          ? const TextStyle(
                                              fontSize: 13,
                                              color: Colors.amber,
                                              fontWeight: FontWeight.bold,
                                              height: 1.5,
                                            )
                                          : TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                              height: 1.5,
                                            ),
                                    ),
                                  ),
                                  _listingCell(index),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _editorController,
                      scrollController: _scrollController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.57,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: hintText,
                        hintStyle: TextStyle(color: Colors.grey),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        _updateLineCount();
                        setState(() {
                          isAssembled = false;
                          _errorLine = null;
                          _breakpointLines.removeWhere(
                            (line) => line >= _lineCount,
                          );
                        });
                        _reportBreakpoints();
                        _reportCursor();
                        _errorMessageController.text =
                            '[NORMAL] Program modified!\n[NORMAL] Please assemble again.';
                        _setLogTypeNormal();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Assembler Logs',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            readOnly: true,
            controller: _errorMessageController,
            maxLines: 3,
            style: TextStyle(
              fontSize: 13,
              color: _isLogTypeError
                  ? Colors.red[600]!
                  : _isLogTypeInfo
                  ? Colors.green[600]!
                  : Colors.white60,
              height: 1.57,
            ),
            decoration: InputDecoration(
              fillColor: Colors.black,
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white12),
                borderRadius: BorderRadius.circular(4),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white12),
                borderRadius: BorderRadius.circular(4),
              ),
              hintStyle: const TextStyle(color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _assembleProgram,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'ASSEMBLE & LOAD',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openProgramBrowserDialog,
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: const Text('Browse Built-In Programs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.withValues(alpha: 0.2),
                      foregroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(
                          color: Colors.blue.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openInstructionSetDialog,
                    icon: const Icon(Icons.edit_document, size: 16),
                    label: const Text('See Instruction Set Reference'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.2),
                      foregroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(
                          color: Colors.green.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
