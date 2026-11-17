import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_8_bit_cpu_simulator/core/io/bridge/protocol.dart';
import 'package:flutter_8_bit_cpu_simulator/core/io/io_ports.dart';
import 'package:flutter_8_bit_cpu_simulator/l10n/board_strings.dart';
import 'package:flutter_8_bit_cpu_simulator/l10n/l10n.dart';

void main() {
  tearDown(() => L10n.debugSet(Lang.en));

  List<String> sample() {
    final t = tBoard;
    final io = IoPorts.standard();
    return [
      t.programCounter,
      t.drivesBus,
      t.busWho('RAM', ['A', 'B']),
      t.stackBytes(2),
      t.ramSummary(256, 8),
      t.noKey,
      t.lcdOff,
      t.noAnswer,
      t.realHardwareTitle,
      io.portName(1),
      io.portName(0),
      io.devices.first.name,
      HardwarePart.matrix.label,
    ];
  }

  test('English text is unchanged', () {
    L10n.debugSet(Lang.en);
    final t = tBoard;
    expect(t.programCounter, 'PROGRAM COUNTER');
    expect(t.busWho('RAM', ['A']), 'RAM drives · A reads');
    expect(t.busWho('RAM', ['A', 'B']), 'RAM drives · A, B read');
    expect(t.stackBytes(1), '1 byte on the stack');
    expect(t.valueCount(3), '3 values');
    expect(IoPorts.standard().portName(2), 'LCD data');
    expect(HardwarePart.lcd.label, 'HD44780 text LCD');
  });

  test('every language has its own non-empty text', () {
    final byLang = <Lang, List<String>>{};
    for (final lang in Lang.values) {
      L10n.debugSet(lang);
      final texts = sample();
      expect(texts.every((s) => s.trim().isNotEmpty), isTrue, reason: '$lang');
      byLang[lang] = texts;
    }
    for (int i = 0; i < byLang[Lang.en]!.length; i++) {
      final set = {for (final lang in Lang.values) byLang[lang]![i]};
      expect(set.length, Lang.values.length, reason: byLang[Lang.en]![i]);
    }
  });

  test('French puts a narrow no-break space before a colon', () {
    L10n.debugSet(Lang.fr);
    expect(tBoard.next('NOP'), 'suivante : NOP');
    expect(tBoard.busWho('RAM', ['A', 'B']), 'RAM pilote · A, B lisent');
  });

  test('German plurals and device names', () {
    L10n.debugSet(Lang.de);
    expect(tBoard.valueCount(1), '1 Wert');
    expect(tBoard.valueCount(2), '2 Werte');
    expect(IoPorts.standard().devices.last.name, 'Tastenfeld');
  });
}
