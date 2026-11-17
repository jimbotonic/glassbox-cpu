/// The GlassBox hardware protocol: ASCII lines ending in `\n`, the same
/// over USB serial and WebSocket. Numbers are two hex digits.
///
/// Host (GlassBox) to board:
///
/// | Line       | Meaning                                         |
/// | ---------- | ----------------------------------------------- |
/// | `HELLO 1`  | handshake, protocol version 1                   |
/// | `W pp vv`  | the CPU wrote `vv` to port `pp`                 |
/// | `RESET`    | put every device back in its power-on state     |
///
/// Board to host:
///
/// | Line                         | Meaning                              |
/// | ---------------------------- | ------------------------------------ |
/// | `GLASSBOX 1 <board> <parts>` | answer to `HELLO`                    |
/// | `A`                          | a `W` or `RESET` line was carried out |
/// | `E <text>`                   | a line was refused; counts as an ack  |
/// | `K xx`                       | key `xx` (ASCII) pressed on the pad  |
/// | `# <text>`                   | a log line, for the connection panel |
///
/// The board answers every host line with exactly one `GLASSBOX`, `A` or
/// `E` line, in order. The host keeps only a few lines unanswered at a
/// time, so a slow board (an LCD on I2C behind a 64-byte serial buffer)
/// is never flooded. `K` and `#` lines can arrive at any time.
library;

import '../../../l10n/board_strings.dart';

const int protocolVersion = 1;

/// Parts a board can report in its `GLASSBOX` line.
enum HardwarePart {
  lcd,
  matrix,
  keypad,
  oled;

  /// Name shown to the user, in the current language.
  String get label => tBoard.hardwarePart(name);
}

String _hex(int v) =>
    (v & 0xFF).toRadixString(16).toUpperCase().padLeft(2, '0');

String helloLine() => 'HELLO $protocolVersion';
String writeLine(int port, int value) => 'W ${_hex(port)} ${_hex(value)}';
const String resetLine = 'RESET';

/// A line from the board.
sealed class BoardMessage {
  const BoardMessage();

  /// Parses one line (without its line ending). Returns null for a line
  /// that is not part of the protocol, such as boot noise from the board.
  static BoardMessage? parse(String line) {
    line = line.trim();
    if (line.isEmpty) return null;
    if (line == 'A') return const Ack();
    if (line.startsWith('# ')) return BoardLog(line.substring(2));
    if (line == '#') return const BoardLog('');
    if (line.startsWith('E')) {
      if (line.length == 1) return const BoardError('');
      if (line[1] == ' ') return BoardError(line.substring(2));
    }
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length == 2 && parts[0] == 'K') {
      final code = int.tryParse(parts[1], radix: 16);
      if (code != null && code > 0 && code < 0x100) return KeyPress(code);
      return null;
    }
    if (parts.length >= 3 && parts[0] == 'GLASSBOX') {
      final version = int.tryParse(parts[1]);
      if (version == null) return null;
      return BoardHello(
        version: version,
        board: parts[2],
        parts: {
          for (final p in parts.skip(3))
            for (final part in HardwarePart.values)
              if (part.name == p.toLowerCase()) part,
        },
      );
    }
    return null;
  }
}

class Ack extends BoardMessage {
  const Ack();
}

class BoardError extends BoardMessage {
  final String message;
  const BoardError(this.message);
}

class BoardLog extends BoardMessage {
  final String message;
  const BoardLog(this.message);
}

class KeyPress extends BoardMessage {
  /// ASCII code of the key, e.g. 0x37 for `7`.
  final int code;
  const KeyPress(this.code);
}

class BoardHello extends BoardMessage {
  final int version;

  /// Board family, e.g. `uno`, `esp32`, `pico`, `raspberrypi`.
  final String board;
  final Set<HardwarePart> parts;

  const BoardHello({
    required this.version,
    required this.board,
    required this.parts,
  });
}

/// Splits a stream of text chunks into lines, whatever the chunking (a
/// serial port delivers bytes as they come). Accepts `\n` and `\r\n`.
class LineSplitter {
  final StringBuffer _pending = StringBuffer();

  /// Lines completed by [chunk].
  List<String> add(String chunk) {
    final lines = <String>[];
    for (final unit in chunk.codeUnits) {
      if (unit == 0x0A) {
        var line = _pending.toString();
        if (line.endsWith('\r')) line = line.substring(0, line.length - 1);
        lines.add(line);
        _pending.clear();
      } else {
        _pending.writeCharCode(unit);
        if (_pending.length > 256) _pending.clear(); // garbage, not a line
      }
    }
    return lines;
  }
}
