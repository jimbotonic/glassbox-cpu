import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../core/assembler.dart';
import '../../core/opcode.dart';
import '../../core/operand.dart';

class AssemblyTextEditingController extends TextEditingController {
  AssemblyTextEditingController({super.text});

  static const Color highlightColor = Color(0x55FFC107); // translucent amber
  static const Color labelColor = Color(0xFFFFD866);
  static const Color directiveColor = Color(0xFF4EC9B0);
  static const Color symbolColor = Color(0xFF9CDCFE);
  static const Color stringColor = Color(0xFFCE9178);

  /// 0-based line drawn with a highlight background (the instruction being
  /// executed), or null. Read in [buildTextSpan], so the owning widget must
  /// rebuild the TextField after changing it.
  int? highlightedLine;

  /// Optional label, then the first word: the mnemonic or directive.
  static final _leadingWord = RegExp(
    r'^(\s*(?:[A-Za-z_]\w*\s*:\s*)?)([A-Za-z]+)\b',
  );

  static final _token = RegExp(
    r'''"(?:[^"\\]|\\.)*"?|'(?:[^'\\]|\\.)*'?|[A-Za-z_.]\w*:?|#|-?(?:0[xX][0-9A-Fa-f]*|0[bB][01]*|\d+)|\s+|.''',
  );

  @override
  set value(TextEditingValue newValue) {
    final normalizedText = newValue.text
        .split('\n')
        .map(_normalizeOpcodeLine)
        .join('\n');

    super.value = normalizedText == newValue.text
        ? newValue
        : newValue.copyWith(text: normalizedText);
  }

  /// Upper-cases a known mnemonic so `lda` reads as `LDA`. Same length, so
  /// the selection stays valid.
  String _normalizeOpcodeLine(String line) {
    final comment = findCommentStart(line);
    final code = comment >= 0 ? line.substring(0, comment) : line;
    final match = _leadingWord.firstMatch(code);
    if (match == null) return line;

    final word = match.group(2)!;
    final upper = word.toUpperCase();
    if (word == upper || !Opcode.values.any((op) => op.mnemonic == upper)) {
      return line;
    }
    final start = match.group(1)!.length;
    return line.replaceRange(start, start + word.length, upper);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final lines = text.split('\n');
    final List<TextSpan> spans = [];

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final lineSpans = _lineSpans(lines[lineIndex], style);
      if (lineIndex == highlightedLine) {
        // Child spans inherit the background from this parent span.
        spans.add(
          TextSpan(
            style: const TextStyle(backgroundColor: highlightColor),
            children: lineSpans,
          ),
        );
      } else {
        spans.addAll(lineSpans);
      }

      if (lineIndex < lines.length - 1) {
        spans.add(TextSpan(text: '\n', style: style));
      }
    }

    return TextSpan(style: style, children: spans);
  }

  List<TextSpan> _lineSpans(String line, TextStyle? style) {
    final spans = <TextSpan>[];
    final comment = findCommentStart(line);
    final code = comment >= 0 ? line.substring(0, comment) : line;

    bool seenKeyword = false;
    bool seenToken = false;
    for (final match in _token.allMatches(code)) {
      final token = match.group(0)!;
      Color? color;
      bool bold = false;

      if (token.trim().isEmpty) {
        spans.add(TextSpan(text: token, style: style));
        continue;
      }

      final first = token[0];
      if (first == '"' || first == "'") {
        color = stringColor;
      } else if (RegExp(r'[A-Za-z_.]').hasMatch(first)) {
        if (token.endsWith(':') && !seenToken) {
          color = labelColor;
        } else if (!seenKeyword) {
          seenKeyword = true;
          bold = true;
          color = first == '.' ? directiveColor : _instructionColor(token);
        } else {
          color = symbolColor;
        }
      } else if (first == '#' || first == '-' || _isDigit(first)) {
        color = _operandColor(token);
      }
      seenToken = true;

      spans.add(
        TextSpan(
          text: token,
          style: style?.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.bold : null,
          ),
        ),
      );
    }

    if (comment >= 0) {
      spans.add(
        TextSpan(
          text: line.substring(comment),
          style: style?.copyWith(
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return spans;
  }

  static bool _isDigit(String c) => '0123456789'.contains(c);

  Color? _instructionColor(String word) {
    final opcode = Opcode.values.firstWhereOrNull(
      (opcode) => opcode.mnemonic == word.toUpperCase(),
    );
    if (opcode == null) return null;
    return opcode.highlightColor.color.withValues(
      alpha: opcode.highlightColor.alpha,
    );
  }

  Color _operandColor(String operand) {
    final highlight =
        OperandPrefix.values
            .firstWhereOrNull((e) => operand.startsWith(e.prefix))
            ?.highlightColor ??
        OperandHighlightColor.decimal;
    return highlight.color.withValues(alpha: highlight.alpha);
  }
}
