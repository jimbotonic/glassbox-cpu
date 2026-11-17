import 'io_ports.dart';
import '../../l10n/board_strings.dart';

/// An 8x8 LED matrix driven a row at a time.
///
/// * [rowPort]: selects the row (0-7) the next data byte goes to.
/// * [dataPort]: the selected row's LEDs, bit 7 on the left; afterwards
///   the matrix moves to the next row, so eight writes fill the picture.
class LedMatrix extends IoDevice {
  LedMatrix({required this.rowPort, required this.dataPort});

  final int rowPort;
  final int dataPort;

  static const int size = 8;

  /// LEDs of each row, bit 7 = leftmost column.
  List<int> get rows => List.unmodifiable(_rows);
  final List<int> _rows = List.filled(size, 0);

  /// Row the next data byte is written to.
  int get selectedRow => _row;
  int _row = 0;

  @override
  String get name => tBoard.ledMatrix;

  @override
  List<int> get ports => [rowPort, dataPort];

  @override
  String portName(int port) =>
      port == rowPort ? tBoard.matrixRowPort : tBoard.matrixDataPort;

  @override
  String portRole(int port) =>
      port == rowPort ? tBoard.rowRole : tBoard.dataRole;

  /// Whether the LED in [row], [column] (0 = left) is lit.
  bool isLit(int row, int column) => (_rows[row] >> (7 - column)) & 1 == 1;

  @override
  void write(int port, int value) {
    if (port == rowPort) {
      _row = value % size;
    } else {
      _rows[_row] = value;
      _row = (_row + 1) % size;
    }
  }

  @override
  int read(int port) => port == rowPort ? _row : _rows[_row];

  @override
  List<(int, int)> replay() => [
    for (int r = 0; r < size; r++) ...[(rowPort, r), (dataPort, _rows[r])],
    (rowPort, _row),
  ];

  @override
  void reset() {
    _rows.fillRange(0, size, 0);
    _row = 0;
  }

  @override
  Object? save() => (List<int>.unmodifiable(_rows), _row);

  @override
  void restore(Object? state) {
    final (rows, row) = state as (List<int>, int);
    _rows.setAll(0, rows);
    _row = row;
  }
}
