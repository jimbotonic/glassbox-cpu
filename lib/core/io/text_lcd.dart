import 'io_ports.dart';

/// A 16x2 character LCD with an HD44780 controller, the chip on almost
/// every hobby LCD module, with its 8-bit interface on two ports.
///
/// * [commandPort]: instructions (clear, display on, move the cursor...).
///   Reading it returns the address counter; the busy flag (bit 7) is
///   always 0, since the simulated chip finishes every instruction at
///   once.
/// * [dataPort]: a character code written at the cursor, which then moves
///   on. Reading it returns the character at the cursor and moves on too.
///
/// As on the real chip, the display is off after power-on: a program must
/// send `0x0C` (display on) before anything shows.
///
/// Instructions, by highest bit set:
///
/// | Byte        | Instruction                                          |
/// | ----------- | ---------------------------------------------------- |
/// | `0x01`      | clear: blanks, cursor home, entry mode left-to-right |
/// | `0x02`      | home: cursor to 0x00, display unshifted              |
/// | `0x04-0x07` | entry mode: bit 1 move right, bit 0 shift display    |
/// | `0x08-0x0F` | display: bit 2 on, bit 1 cursor, bit 0 blink         |
/// | `0x10-0x1F` | shift: bit 3 display (else cursor), bit 2 right      |
/// | `0x20-0x3F` | function set: bit 3 two lines                        |
/// | `0x40-0x7F` | CGRAM address: define custom characters 0-7          |
/// | `0x80-0xFF` | DDRAM address: line 1 starts at 0x00, line 2 at 0x40 |
class TextLcd extends IoDevice {
  TextLcd({required this.commandPort, required this.dataPort}) {
    reset();
  }

  final int commandPort;
  final int dataPort;

  static const int columns = 16;
  static const int rows = 2;

  /// Characters each line holds in memory; 16 of them are visible.
  static const int lineLength = 40;

  /// DDRAM address of the start of line 2.
  static const int line2 = 0x40;

  final List<int> _ddram = List.filled(0x80, 0x20);
  final List<int> _cgram = List.filled(64, 0);

  /// Address counter: DDRAM or CGRAM address of the cursor.
  int get address => _address;
  int _address = 0;

  /// Whether [address] points into CGRAM (after a CGRAM address command).
  bool get addressingCgram => _cgMode;
  bool _cgMode = false;

  bool get displayOn => _displayOn;
  bool _displayOn = false;

  bool get cursorOn => _cursorOn;
  bool _cursorOn = false;

  bool get blinkOn => _blinkOn;
  bool _blinkOn = false;

  /// Entry mode: the cursor moves right after each character (else left).
  bool get moveRight => _moveRight;
  bool _moveRight = true;

  /// Entry mode: the display shifts with each character.
  bool get shiftOnWrite => _shiftOnWrite;
  bool _shiftOnWrite = false;

  bool get twoLines => _twoLines;
  bool _twoLines = true;

  /// How far the display is shifted left, 0-39.
  int get displayShift => _shift;
  int _shift = 0;

  /// The last instruction byte written, for the UI.
  int? get lastCommand => _lastCommand;
  int? _lastCommand;

  @override
  String get name => 'Text LCD';

  @override
  List<int> get ports => [commandPort, dataPort];

  @override
  String portName(int port) => port == commandPort ? 'LCD command' : 'LCD data';

  /// Character code shown at [row], [column] of the screen.
  int charAt(int row, int column) =>
      _ddram[row * line2 + (column + _shift) % lineLength];

  /// Screen column of the cursor on [row], or null if it is elsewhere
  /// (another line, scrolled out of view, or in CGRAM).
  int? cursorColumn(int row) {
    if (_cgMode) return null;
    final line = _address >= line2 ? 1 : 0;
    if (line != row) return null;
    final offset = _address - line * line2;
    if (offset >= lineLength) return null;
    final column = (offset - _shift) % lineLength;
    return column < columns ? column : null;
  }

  /// Rows of custom character [code] (0-7; 8-15 mirror them), 5 bits
  /// each, bit 4 on the left.
  List<int> customGlyph(int code) {
    final start = (code & 7) * 8;
    return List.unmodifiable(_cgram.sublist(start, start + 8));
  }

  @override
  void write(int port, int value) {
    if (port == commandPort) {
      _command(value);
    } else {
      _writeData(value);
    }
  }

  void _command(int v) {
    _lastCommand = v;
    if (v & 0x80 != 0) {
      _address = v & 0x7F;
      _cgMode = false;
    } else if (v & 0x40 != 0) {
      _address = v & 0x3F;
      _cgMode = true;
    } else if (v & 0x20 != 0) {
      _twoLines = v & 0x08 != 0;
    } else if (v & 0x10 != 0) {
      final right = v & 0x04 != 0;
      if (v & 0x08 != 0) {
        _shiftDisplay(right);
      } else {
        _cgMode = false;
        _moveCursor(right);
      }
    } else if (v & 0x08 != 0) {
      _displayOn = v & 0x04 != 0;
      _cursorOn = v & 0x02 != 0;
      _blinkOn = v & 0x01 != 0;
    } else if (v & 0x04 != 0) {
      _moveRight = v & 0x02 != 0;
      _shiftOnWrite = v & 0x01 != 0;
    } else if (v & 0x02 != 0) {
      _address = 0;
      _cgMode = false;
      _shift = 0;
    } else if (v & 0x01 != 0) {
      _ddram.fillRange(0, _ddram.length, 0x20);
      _address = 0;
      _cgMode = false;
      _shift = 0;
      _moveRight = true;
    }
  }

  void _writeData(int v) {
    if (_cgMode) {
      _cgram[_address] = v & 0x1F;
      _address = (_address + (_moveRight ? 1 : -1)) & 0x3F;
      return;
    }
    _ddram[_address] = v;
    _moveCursor(_moveRight);
    if (_shiftOnWrite) _shiftDisplay(!_moveRight);
  }

  /// Moves the address counter one place within DDRAM: with two lines,
  /// the end of line 1 (0x27) continues at line 2 (0x40) and back.
  void _moveCursor(bool right) {
    if (!_twoLines) {
      _address = (_address + (right ? 1 : -1)) % 0x50;
      return;
    }
    if (right) {
      _address = switch (_address) {
        0x27 => 0x40,
        0x67 => 0x00,
        final a => (a + 1) & 0x7F,
      };
    } else {
      _address = switch (_address) {
        0x40 => 0x27,
        0x00 => 0x67,
        final a => (a - 1) & 0x7F,
      };
    }
  }

  /// Shifting the display right shows earlier characters.
  void _shiftDisplay(bool right) =>
      _shift = (_shift + (right ? -1 : 1)) % lineLength;

  @override
  int read(int port) {
    if (port == commandPort) return _address & 0x7F;
    final value = _cgMode ? _cgram[_address] : _ddram[_address];
    if (_cgMode) {
      _address = (_address + (_moveRight ? 1 : -1)) & 0x3F;
    } else {
      _moveCursor(_moveRight);
    }
    return value;
  }

  @override
  int peek(int port) => port == commandPort
      ? _address & 0x7F
      : (_cgMode ? _cgram[_address] : _ddram[_address]);

  @override
  void reset() {
    _ddram.fillRange(0, _ddram.length, 0x20);
    _cgram.fillRange(0, _cgram.length, 0);
    _address = 0;
    _cgMode = false;
    _displayOn = false;
    _cursorOn = false;
    _blinkOn = false;
    _moveRight = true;
    _shiftOnWrite = false;
    _twoLines = true;
    _shift = 0;
    _lastCommand = null;
  }

  @override
  Object? save() => _LcdState(
    List.unmodifiable(_ddram),
    List.unmodifiable(_cgram),
    _address,
    _cgMode,
    _displayOn,
    _cursorOn,
    _blinkOn,
    _moveRight,
    _shiftOnWrite,
    _twoLines,
    _shift,
    _lastCommand,
  );

  @override
  void restore(Object? state) {
    final s = state as _LcdState;
    _ddram.setAll(0, s.ddram);
    _cgram.setAll(0, s.cgram);
    _address = s.address;
    _cgMode = s.cgMode;
    _displayOn = s.displayOn;
    _cursorOn = s.cursorOn;
    _blinkOn = s.blinkOn;
    _moveRight = s.moveRight;
    _shiftOnWrite = s.shiftOnWrite;
    _twoLines = s.twoLines;
    _shift = s.shift;
    _lastCommand = s.lastCommand;
  }
}

class _LcdState {
  final List<int> ddram;
  final List<int> cgram;
  final int address;
  final bool cgMode;
  final bool displayOn;
  final bool cursorOn;
  final bool blinkOn;
  final bool moveRight;
  final bool shiftOnWrite;
  final bool twoLines;
  final int shift;
  final int? lastCommand;

  const _LcdState(
    this.ddram,
    this.cgram,
    this.address,
    this.cgMode,
    this.displayOn,
    this.cursorOn,
    this.blinkOn,
    this.moveRight,
    this.shiftOnWrite,
    this.twoLines,
    this.shift,
    this.lastCommand,
  );
}
