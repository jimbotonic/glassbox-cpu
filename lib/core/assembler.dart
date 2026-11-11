import 'opcode.dart';

/// An assembly error, tied to a 1-based source line when there is one.
class AssemblerError implements Exception {
  final String message;

  /// 1-based source line, or null for whole-program errors.
  final int? line;

  const AssemblerError(this.message, {this.line});

  @override
  String toString() => line == null ? message : 'Line $line: $message';
}

/// Machine code plus, for each address, the 0-based source line it came from.
class AssemblyResult {
  final List<int> machineCode;
  final List<int> sourceLines;

  /// Addresses filled by `.db` rather than by an instruction.
  final Set<int> dataAddresses;

  /// Labels and `.equ` constants, keyed by upper-case name.
  final Map<String, int> symbols;

  const AssemblyResult(
    this.machineCode,
    this.sourceLines, {
    this.dataAddresses = const {},
    this.symbols = const {},
  });

  /// Source line of the byte at [address], or null if there is none.
  int? lineForAddress(int address) =>
      address >= 0 && address < sourceLines.length
      ? sourceLines[address]
      : null;

  /// Address of the instruction on source [line], or null if that line
  /// holds no instruction (blank, comment, label only, `.equ`, or `.db`).
  int? addressForLine(int line) {
    final address = sourceLines.indexOf(line);
    return address < 0 || dataAddresses.contains(address) ? null : address;
  }

  /// All addresses filled from source [line], in order.
  List<int> addressesForLine(int line) => [
    for (int a = 0; a < sourceLines.length; a++)
      if (sourceLines[a] == line) a,
  ];
}

/// Index of the `;` that starts a comment in [line], ignoring any inside
/// string or character literals, or -1 if there is no comment.
int findCommentStart(String line) {
  String? quote;
  for (int i = 0; i < line.length; i++) {
    final c = line[i];
    if (quote != null) {
      if (c == r'\') {
        i++;
      } else if (c == quote) {
        quote = null;
      }
    } else if (c == '"' || c == "'") {
      quote = c;
    } else if (c == ';') {
      return i;
    }
  }
  return -1;
}

final RegExp _labelPattern = RegExp(r'^([A-Za-z_]\w*)\s*:');
final RegExp _identifierPattern = RegExp(r'^[A-Za-z_]\w*$');

/// Two-pass assembler.
///
/// Each line is `[label:] [instruction | directive] [; comment]`:
///
/// ```text
/// .equ STEP 1          ; named constant
/// loop:  LDA count     ; labels name addresses
///        SUB one
///        JZ  done
///        JMP loop
/// done:  HLT
/// count: .db 10        ; data bytes (values, labels, "strings", 'c')
/// one:   .db STEP
/// ```
///
/// Operands may be decimal, `0x` hex, `0b` binary, a character `'A'`, or a
/// label or constant name; a leading `#` is optional. Names are not
/// case-sensitive.
class Assembler {
  /// Bytes of RAM the program must fit into.
  final int memorySize;

  Assembler({this.memorySize = 16});

  List<int> assemble(String source) =>
      assembleWithSourceMap(source).machineCode;

  AssemblyResult assembleWithSourceMap(String source) {
    final statements = _parse(source);
    final symbols = <String, int>{};

    // Pass 1: give every label an address and every constant its value.
    int address = 0;
    for (final s in statements) {
      if (s.label != null) {
        _define(symbols, s.label!, address, s.line);
      }
      switch (s.keyword) {
        case null:
          break;
        case '.EQU':
          final (name, valueText) = _splitEqu(s);
          _define(symbols, name, _value(valueText, symbols, s.line), s.line);
        case '.DB':
          s.size = _dataItems(s).fold(0, (n, item) => n + item.size);
        default:
          if (s.keyword!.startsWith('.')) {
            throw AssemblerError(
              'Unknown directive "${s.keyword!.toLowerCase()}"',
              line: s.line,
            );
          }
          s.size = 1;
      }
      address += s.size;
    }

    if (address == 0) throw const AssemblerError('Program is empty');
    if (address > memorySize) {
      throw AssemblerError(
        'Program needs $address bytes but RAM holds only $memorySize',
      );
    }

    // Pass 2: emit bytes, now that forward references can be resolved.
    final machineCode = <int>[];
    final sourceLines = <int>[];
    final dataAddresses = <int>{};
    for (final s in statements) {
      if (s.size == 0) continue;
      if (s.keyword == '.DB') {
        for (final item in _dataItems(s)) {
          for (final byte in item.bytes(symbols)) {
            dataAddresses.add(machineCode.length);
            machineCode.add(byte);
            sourceLines.add(s.line - 1);
          }
        }
      } else {
        machineCode.add(_instruction(s, symbols));
        sourceLines.add(s.line - 1);
      }
    }

    return AssemblyResult(
      machineCode,
      sourceLines,
      dataAddresses: dataAddresses,
      symbols: symbols,
    );
  }

  List<_Statement> _parse(String source) {
    final statements = <_Statement>[];
    final lines = source.split('\n');
    for (int i = 0; i < lines.length; i++) {
      var text = lines[i];
      final comment = findCommentStart(text);
      if (comment >= 0) text = text.substring(0, comment);
      text = text.trim();
      if (text.isEmpty) continue;

      String? label;
      final match = _labelPattern.firstMatch(text);
      if (match != null) {
        label = match.group(1);
        text = text.substring(match.end).trim();
      }

      String? keyword;
      String operands = '';
      if (text.isNotEmpty) {
        final space = text.indexOf(RegExp(r'\s'));
        keyword = (space < 0 ? text : text.substring(0, space)).toUpperCase();
        operands = space < 0 ? '' : text.substring(space + 1).trim();
      }
      statements.add(_Statement(i + 1, label, keyword, operands));
    }
    return statements;
  }

  void _define(Map<String, int> symbols, String name, int value, int line) {
    final key = name.toUpperCase();
    if (Opcode.values.any((op) => op.mnemonic == key)) {
      throw AssemblerError(
        '"$name" is an instruction and cannot be a name',
        line: line,
      );
    }
    if (symbols.containsKey(key)) {
      throw AssemblerError('"$name" is already defined', line: line);
    }
    symbols[key] = value;
  }

  (String, String) _splitEqu(_Statement s) {
    final parts = s.operands.split(RegExp(r'\s*,\s*|\s+'));
    if (parts.length != 2 || !_identifierPattern.hasMatch(parts[0])) {
      throw AssemblerError('Expected ".equ NAME value"', line: s.line);
    }
    return (parts[0], parts[1]);
  }

  int _instruction(_Statement s, Map<String, int> symbols) {
    final opcode = Opcode.values
        .where((op) => op.mnemonic == s.keyword)
        .firstOrNull;
    if (opcode == null) {
      throw AssemblerError('Unknown instruction "${s.keyword}"', line: s.line);
    }

    final parts = s.operands.isEmpty
        ? const <String>[]
        : s.operands.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      throw AssemblerError('Unexpected "${parts[1]}"', line: s.line);
    }
    if (parts.isEmpty) {
      if (opcode.requiresOperand) {
        throw AssemblerError(
          '${opcode.mnemonic} requires an operand',
          line: s.line,
        );
      }
      return opcode.hex << 4;
    }

    final operand = _value(parts[0], symbols, s.line);
    if (operand < 0 || operand > 15) {
      throw AssemblerError(
        'Operand must be 0-15 (4-bit), got $operand',
        line: s.line,
      );
    }
    return (opcode.hex << 4) | operand;
  }

  /// Splits the operands of a `.db` line on commas outside quotes.
  List<_DataItem> _dataItems(_Statement s) {
    final text = s.operands;
    if (text.isEmpty) {
      throw AssemblerError('.db needs at least one value', line: s.line);
    }

    final items = <_DataItem>[];
    final buffer = StringBuffer();
    void flush() {
      final item = buffer.toString().trim();
      if (item.isEmpty) {
        throw AssemblerError('Missing value in .db', line: s.line);
      }
      items.add(_DataItem(item, s.line, this));
      buffer.clear();
    }

    String? quote;
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      if (quote != null) {
        buffer.write(c);
        if (c == r'\' && i + 1 < text.length) {
          buffer.write(text[++i]);
        } else if (c == quote) {
          quote = null;
        }
      } else if (c == ',') {
        flush();
      } else {
        if (c == '"' || c == "'") quote = c;
        buffer.write(c);
      }
    }
    flush();
    return items;
  }

  /// Value of a numeric literal, character literal, or symbol.
  int _value(String text, Map<String, int> symbols, int line) {
    var t = text.startsWith('#') ? text.substring(1) : text;
    final negative = t.startsWith('-');
    if (negative) t = t.substring(1);

    int? value;
    final lower = t.toLowerCase();
    if (lower.startsWith('0x')) {
      value = int.tryParse(t.substring(2), radix: 16);
    } else if (lower.startsWith('0b')) {
      value = int.tryParse(t.substring(2), radix: 2);
    } else if (t.startsWith("'")) {
      final chars = _unescape(t, "'", line);
      if (chars.length != 1) {
        throw AssemblerError(
          'Character literal $t must hold one character',
          line: line,
        );
      }
      value = chars.first;
    } else if (RegExp(r'^\d+$').hasMatch(t)) {
      value = int.parse(t);
    } else if (_identifierPattern.hasMatch(t)) {
      value = symbols[t.toUpperCase()];
      if (value == null) {
        throw AssemblerError('Unknown name "$t"', line: line);
      }
    }
    if (value == null) {
      throw AssemblerError('Invalid operand "$text"', line: line);
    }
    return negative ? -value : value;
  }

  /// Character codes of a quoted literal, with `\n \t \0 \\ \" \'` escapes.
  List<int> _unescape(String text, String quote, int line) {
    if (text.length < 2 ||
        !text.startsWith(quote) ||
        !text.endsWith(quote) ||
        text == '$quote\\$quote') {
      throw AssemblerError('Unterminated literal $text', line: line);
    }
    final body = text.substring(1, text.length - 1);
    final codes = <int>[];
    for (int i = 0; i < body.length; i++) {
      var c = body[i];
      if (c == r'\' && i + 1 < body.length) {
        c = switch (body[++i]) {
          'n' => '\n',
          't' => '\t',
          '0' => '\x00',
          final other => other,
        };
      }
      final code = c.codeUnitAt(0);
      if (code > 0xFF) {
        throw AssemblerError('"$c" does not fit in a byte', line: line);
      }
      codes.add(code);
    }
    return codes;
  }
}

class _Statement {
  final int line;
  final String? label;

  /// Upper-case mnemonic or directive, or null for a label-only line.
  final String? keyword;
  final String operands;

  /// Bytes this statement occupies, set in pass 1.
  int size = 0;

  _Statement(this.line, this.label, this.keyword, this.operands);
}

class _DataItem {
  final String text;
  final int line;
  final Assembler assembler;

  _DataItem(this.text, this.line, this.assembler);

  bool get isString => text.startsWith('"');

  int get size => isString ? assembler._unescape(text, '"', line).length : 1;

  List<int> bytes(Map<String, int> symbols) {
    if (isString) return assembler._unescape(text, '"', line);
    final value = assembler._value(text, symbols, line);
    if (value < -128 || value > 255) {
      throw AssemblerError('Byte must be -128..255, got $value', line: line);
    }
    return [value & 0xFF];
  }
}
