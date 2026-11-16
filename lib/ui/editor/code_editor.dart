import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../core/assembler.dart';
import '../../core/builtin_program_list.dart';
import '../../core/cpu_mode.dart';
import '../board/glass_widgets.dart';
import '../theme/glass.dart';
import 'assembly_text_editing_controller.dart';
import 'builtin_program_browser_dialog.dart';
import 'instruction_set_dialog.dart';
import 'line_comment.dart';

class ProgramEditor extends StatefulWidget {
  /// Called after each assembly with its result, or null on an error.
  final ValueChanged<AssemblyResult?> onAssemble;
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

  /// Machine the program is assembled for.
  final CpuMode mode;

  /// Asked to switch machine, when a built-in program for the other one is
  /// opened.
  final ValueChanged<CpuMode>? onModeChanged;

  const ProgramEditor({
    super.key,
    required this.onAssemble,
    this.initialProgram,
    this.currentAddress,
    this.onBreakpointsChanged,
    this.onCursorAddressChanged,
    this.mode = CpuMode.classic,
    this.onModeChanged,
  });

  @override
  State<ProgramEditor> createState() => _ProgramEditorState();
}

class _ProgramEditorState extends State<ProgramEditor> {
  static const _programs = BuiltinProgramList.all;
  static final _categories = BuiltinProgramList.getCategories();

  late final TextEditingController _errorMessageController;
  late final AssemblyTextEditingController _editorController;

  late final ScrollController _scrollController;
  late final ScrollController _lineNumberScrollController;
  final ScrollController _horizontalScrollController = ScrollController();

  static const TextStyle _codeStyle = TextStyle(
    fontFamily: Glass.mono,
    fontSize: 13,
    color: Glass.text,
    height: 1.57,
    // TextField merges in the theme's body style, whose letter spacing
    // would widen lines past the measured width and wrap them.
    letterSpacing: 0,
  );

  /// Width the code needs without wrapping: its widest line, measured as
  /// drawn (bold mnemonics, italic comments), plus the field's padding.
  double _codeWidth(BuildContext context) {
    final painter = TextPainter(
      text: _editorController.buildTextSpan(
        context: context,
        style: _codeStyle,
        withComposing: false,
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width + 40;
  }

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

  /// Line whose comment the hint box shows: the cursor's line after an
  /// edit or click, the executing line after a step.
  int? _focusLine;

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
      if (line != _focusLine) {
        Future.microtask(() {
          if (mounted) setState(() => _focusLine = line);
        });
      }
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
    final digits = widget.mode.addressDigits;
    final bytes = [for (final a in addresses) hex(assembly.machineCode[a], 2)];
    final first = addresses.first;
    final range = addresses.length == 1
        ? '0x${hex(first, digits)}'
        : '0x${hex(first, digits)}-0x${hex(addresses.last, digits)}';
    return (
      text:
          '${hex(first, digits)} ${bytes.first}${bytes.length > 1 ? '+' : ''}',
      tooltip: '$range: ${bytes.join(' ')}',
      isData: assembly.dataAddresses.contains(first),
    );
  }

  double get _listingWidth => widget.mode == CpuMode.classic ? 46 : 54;

  /// Listing column: address and first byte assembled from [line], e.g.
  /// `3 4F`, with a `+` when the line fills several bytes (a `.db` line,
  /// or an Extended instruction and its operand byte).
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
                    style: const TextStyle(color: Glass.faint),
                  ),
                  TextSpan(
                    text: listing.text.substring(listing.text.indexOf(' ')),
                    style: TextStyle(
                      color: listing.isData
                          ? AssemblyTextEditingController.stringColor
                          : Glass.synComment,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: Glass.mono,
                fontSize: 11,
                height: 1.5 * 13 / 11,
              ),
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
      text: 'Write a program or open a built-in one, then assemble.',
    );
    _scrollController = ScrollController();
    _lineNumberScrollController = ScrollController();
    _scrollController.addListener(_syncLineNumberScroll);
    _updateLineCount();
  }

  @override
  void didUpdateWidget(ProgramEditor old) {
    super.didUpdateWidget(old);
    if (old.currentAddress != widget.currentAddress) {
      final line = _highlightedLine;
      if (line != null) _focusLine = line;
    }
    if (old.mode != widget.mode) {
      // The CPU was switched and its RAM cleared: the old assembly is gone.
      setState(() {
        isAssembled = false;
        _assembly = null;
        _errorLine = null;
      });
      _errorMessageController.text =
          '${widget.mode.label} CPU: ${widget.mode.description}. '
          'RAM cleared: assemble again.';
      _setLogTypeNormal();
      // The board is mid-build here: tell it about breakpoints afterwards.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reportBreakpoints();
      });
      _reportCursor();
    }
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
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _assembleProgram() {
    try {
      final assembly = Assembler(
        mode: widget.mode,
      ).assembleWithSourceMap(_editorController.text);
      final program = assembly.machineCode;
      setState(() {
        isAssembled = true;
        _assembly = assembly;
        _errorLine = null;
      });
      _errorMessageController.text =
          'Assembled for ${widget.mode.label}: ${program.length} of '
          '${widget.mode.ramSize} bytes, loaded into RAM.';
      _setLogTypeInfo();
      widget.onAssemble(assembly);
      _reportBreakpoints();
      _reportCursor();
    } catch (e) {
      setState(() {
        isAssembled = false;
        final line = e is AssemblerError ? e.line : null;
        _errorLine = line == null ? null : line - 1;
      });
      _errorMessageController.text = e.toString();
      _setLogTypeError();
      widget.onAssemble(null);
      _reportBreakpoints();
      _reportCursor();
    }
  }

  void _openProgramBrowserDialog() {
    showGlassDialog<void>(
      context,
      child: BuiltinProgramBrowserDialog(
        programs: _programs,
        categories: _categories,
        currentMode: widget.mode,
        onProgramSelected: (program) {
          if (program.mode != widget.mode) {
            widget.onModeChanged?.call(program.mode);
          }
          setState(() {
            isAssembled = false;
            _errorLine = null;
            _breakpointLines.clear();
          });
          _editorController.text = program.code;
          _updateLineCount();
          _reportBreakpoints();
          _errorMessageController.text =
              'Opened for the ${program.mode.label} CPU. '
              'Assemble & load to put it in RAM.';
          _setLogTypeNormal();
        },
      ),
    );
  }

  void _openInstructionSetDialog() {
    showGlassDialog<void>(
      context,
      child: InstructionSetDialog(mode: widget.mode),
    );
  }

  Widget _codeField(String hintText) => Padding(
    padding: const EdgeInsets.all(8),
    child: TextField(
      controller: _editorController,
      scrollController: _scrollController,
      maxLines: null,
      expands: true,
      style: _codeStyle,
      cursorColor: Glass.bus,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hintText,
        hintStyle: const TextStyle(color: Glass.faint),
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (value) {
        _updateLineCount();
        setState(() {
          isAssembled = false;
          _errorLine = null;
          _breakpointLines.removeWhere((line) => line >= _lineCount);
        });
        _reportBreakpoints();
        _reportCursor();
        _errorMessageController.text =
            'Program modified. Assemble again to load it.';
        _setLogTypeNormal();
      },
    ),
  );

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

    final status = _isLogTypeError
        ? ('error', Glass.led)
        : isAssembled
        ? (
            'assembled · ${_assembly?.machineCode.length ?? 0} of '
                '${widget.mode.ramSize} bytes',
            Glass.okText,
          )
        : ('not assembled', Glass.muted);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Glass.panel,
        borderRadius: BorderRadius.circular(Glass.radius),
        border: Border.all(
          color: _isLogTypeError
              ? Glass.led
              : isAssembled
              ? const Color(0xFF1F4D3A)
              : Glass.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(child: Text('PROGRAM', style: Glass.panelTitle)),
              Text(status.$1, style: TextStyle(fontSize: 12, color: status.$2)),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Glass.ground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Glass.borderSoft),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: (_lineCount > 99 ? 44 : 34) + _listingWidth,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Glass.sunken,
                      border: Border(
                        right: BorderSide(color: Glass.borderSoft),
                      ),
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
                                            ? Glass.led
                                            : Colors.transparent,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${index + 1}',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontFamily: Glass.mono,
                                          fontSize: 13,
                                          height: 1.5,
                                          fontWeight:
                                              index == _errorLine ||
                                                  index == highlightedLine
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: index == _errorLine
                                              ? Glass.led
                                              : index == highlightedLine
                                              ? Glass.bus
                                              : Glass.faint,
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
                  // Lines never wrap, so each stays level with its number in
                  // the gutter; long lines scroll sideways instead.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Scrollbar(
                        controller: _horizontalScrollController,
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: math.max(
                              constraints.maxWidth,
                              _codeWidth(context),
                            ),
                            child: _codeField(hintText),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GlassButton(
            label: 'Assemble & load',
            height: 44,
            fill: Glass.ok,
            foreground: const Color(0xFF04140C),
            onPressed: _assembleProgram,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Built-in programs',
                  icon: FluentIcons.folder_open_24_regular,
                  onPressed: _openProgramBrowserDialog,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassButton(
                  label: 'Instruction set',
                  icon: FluentIcons.book_24_regular,
                  onPressed: _openInstructionSetDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            label: 'Assembler log',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Glass.ground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _errorMessageController,
                builder: (context, value, _) {
                  final focus = _focusLine;
                  final comment = _isLogTypeError || focus == null
                      ? null
                      : commentForLine(_editorController.text, focus);
                  if (comment != null) return _commentHint(focus!, comment);
                  return Text(
                    value.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: Glass.mono,
                      fontSize: 11.5,
                      height: 1.6,
                      color: _isLogTypeError
                          ? Glass.led
                          : _isLogTypeInfo
                          ? Glass.okText
                          : Glass.muted,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The focus line's comment in full, so a long one needs no scrolling.
  Widget _commentHint(int line, String comment) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: 'line ${line + 1}  ',
          style: const TextStyle(
            color: Glass.faint,
            fontStyle: FontStyle.normal,
          ),
        ),
        TextSpan(text: comment),
      ],
    ),
    maxLines: 4,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontFamily: Glass.mono,
      fontSize: 11.5,
      height: 1.6,
      fontStyle: FontStyle.italic,
      color: AssemblyTextEditingController.commentColor,
    ),
  );
}
