import 'io_ports.dart';
import '../../l10n/board_strings.dart';

/// A 4x4 keypad on one input port.
///
/// Reading [port] returns the ASCII code of the last key pressed, then
/// forgets it, so each press is read once; with no key waiting it returns
/// 0. ASCII codes can go straight to the LCD's data port.
class Keypad extends IoDevice {
  Keypad({required this.port});

  final int port;

  /// Key labels as laid out on the pad, row by row.
  static const List<String> layout = [
    '1', '2', '3', 'A', //
    '4', '5', '6', 'B',
    '7', '8', '9', 'C',
    '*', '0', '#', 'D',
  ];

  /// ASCII code of the key waiting to be read, or null.
  int? get pending => _pending;
  int? _pending;

  @override
  String get name => tBoard.keypad;

  @override
  List<int> get ports => [port];

  @override
  String portName(int port) => tBoard.keypadPort;

  /// The user presses [key], one of [layout]. A key not yet read is
  /// replaced, as a one-key buffer would.
  void press(String key) {
    assert(layout.contains(key), 'Unknown key $key');
    _pending = key.codeUnitAt(0);
  }

  @override
  void write(int port, int value) {} // input only

  @override
  int read(int port) {
    final value = _pending ?? 0;
    _pending = null;
    return value;
  }

  @override
  int peek(int port) => _pending ?? 0;

  @override
  void reset() => _pending = null;

  @override
  Object? save() => _pending;

  @override
  void restore(Object? state) => _pending = state as int?;
}
