import 'dart:async';

import 'package:flutter_8_bit_cpu_simulator/core/assembler.dart';
import 'package:flutter_8_bit_cpu_simulator/core/builtin_program_list.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu_mode.dart';
import 'package:flutter_8_bit_cpu_simulator/core/io/bridge/hardware_bridge.dart';
import 'package:flutter_8_bit_cpu_simulator/core/io/bridge/protocol.dart';
import 'package:flutter_8_bit_cpu_simulator/core/io/io_ports.dart';
import 'package:flutter_8_bit_cpu_simulator/core/io/keypad.dart';
import 'package:flutter_8_bit_cpu_simulator/core/io/led_matrix.dart';
import 'package:flutter_8_bit_cpu_simulator/core/io/text_lcd.dart';
import 'package:flutter_test/flutter_test.dart';

const extended = CpuMode.extended;

Cpu runProgram(String name, {int maxSteps = 5000}) {
  final program = BuiltinProgramList.getByName(name)!;
  final cpu = Cpu(mode: extended)
    ..load(Assembler(mode: extended).assemble(program.code));
  for (int i = 0; i < maxSteps && !cpu.halted; i++) {
    cpu.stepInstruction();
  }
  return cpu;
}

/// Everything visible about an LCD, for comparing two of them.
Map<String, Object?> lcdView(TextLcd lcd) => {
  'text': [
    for (int r = 0; r < TextLcd.rows; r++)
      String.fromCharCodes([
        for (int c = 0; c < TextLcd.columns; c++) lcd.charAt(r, c),
      ]),
  ],
  'cursor': [lcd.cursorColumn(0), lcd.cursorColumn(1)],
  'address': lcd.address,
  'cgram': lcd.addressingCgram,
  'flags': [lcd.displayOn, lcd.cursorOn, lcd.blinkOn, lcd.moveRight],
  'shiftOnWrite': lcd.shiftOnWrite,
  'shift': lcd.displayShift,
  'glyphs': [for (int g = 0; g < 8; g++) lcd.customGlyph(g)],
};

/// A board on the other end of a pipe: answers like the firmware does.
class FakeLink implements HardwareLink {
  FakeLink({
    this.window = 4,
    this.answerHelloAfter = 1,
    this.hello = 'GLASSBOX 1 fake lcd matrix keypad',
    this.autoAck = true,
  });

  @override
  final int window;
  final int answerHelloAfter;
  final String hello;
  bool autoAck;

  final sent = <String>[];
  final _received = StreamController<String>();
  int unanswered = 0;
  bool opened = false, closed = false;
  int maxInFlight = 0;
  int _hellos = 0;

  @override
  String get description => 'fake';

  @override
  Future<void> open() async => opened = true;

  @override
  Stream<String> get received => _received.stream;

  void reply(String text) {
    if (!_received.isClosed) _received.add(text);
  }

  /// Acks every line still waiting.
  void ackAll() {
    final n = unanswered;
    unanswered = 0;
    reply('A\n' * n);
  }

  @override
  void send(String line) {
    sent.add(line);
    if (line.startsWith('HELLO')) {
      if (++_hellos >= answerHelloAfter) {
        // Split across chunks, as a serial port may deliver it.
        scheduleMicrotask(() {
          reply(hello.substring(0, 5));
          reply('${hello.substring(5)}\r\n');
        });
      }
      return;
    }
    unanswered++;
    if (unanswered > maxInFlight) maxInFlight = unanswered;
    if (autoAck) scheduleMicrotask(ackAll);
  }

  @override
  Future<void> close() async {
    closed = true;
    await _received.close();
  }

  List<String> get writes => sent.where((l) => !l.startsWith('HELLO')).toList();
}

Future<void> settle() => Future.delayed(const Duration(milliseconds: 20));

void main() {
  group('protocol', () {
    test('formats host lines in hex', () {
      expect(helloLine(), 'HELLO 1');
      expect(writeLine(2, 0x41), 'W 02 41');
      expect(writeLine(255, 300), 'W FF 2C');
    });

    test('parses board lines', () {
      final hello =
          BoardMessage.parse('GLASSBOX 1 esp32 lcd OLED keypad x')
              as BoardHello;
      expect(hello.version, 1);
      expect(hello.board, 'esp32');
      expect(hello.parts, {
        HardwarePart.lcd,
        HardwarePart.oled,
        HardwarePart.keypad,
      });
      expect(BoardMessage.parse('A'), isA<Ack>());
      expect((BoardMessage.parse('K 37') as KeyPress).code, 0x37);
      expect(
        (BoardMessage.parse('E bad line') as BoardError).message,
        'bad line',
      );
      expect((BoardMessage.parse('# booted') as BoardLog).message, 'booted');
      expect(BoardMessage.parse('ets Jun  8 2016 boot noise'), isNull);
      expect(BoardMessage.parse('K zz'), isNull);
      expect(BoardMessage.parse('  '), isNull);
    });

    test('splits chunks into lines', () {
      final s = LineSplitter();
      expect(s.add('A\nK 3'), ['A']);
      expect(s.add('7\r\n# hi\n'), ['K 37', '# hi']);
      expect(s.add(''), isEmpty);
    });
  });

  group('replay', () {
    for (final name in const ['LCD: Hello, world', 'LCD: custom character']) {
      test('rebuilds the LCD of "$name"', () {
        final lcd = runProgram(name).io.device<TextLcd>()!;
        final copy = TextLcd(commandPort: 1, dataPort: 2);
        for (final (port, value) in lcd.replay()) {
          copy.write(port, value);
        }
        expect(lcdView(copy), lcdView(lcd));
      });
    }

    test('rebuilds a shifted LCD with the cursor on, writing leftwards', () {
      final lcd = TextLcd(commandPort: 1, dataPort: 2);
      for (final v in [0x38, 0x0F, 0x01]) {
        lcd.write(1, v);
      }
      for (final c in 'Scrolling text, far beyond 16'.codeUnits) {
        lcd.write(2, c);
      }
      for (final v in [0x18, 0x18, 0x18, 0xC5, 0x04]) {
        lcd.write(1, v); // shift left x3, line 2 col 5, write leftwards
      }
      lcd.write(2, 0x7E);
      final copy = TextLcd(commandPort: 1, dataPort: 2);
      for (final (port, value) in lcd.replay()) {
        copy.write(port, value);
      }
      expect(lcdView(copy), lcdView(lcd));
    });

    test('rebuilds the LED matrix, selected row included', () {
      final matrix = runProgram('LED matrix: smiley').io.device<LedMatrix>()!;
      matrix.write(3, 5);
      final copy = LedMatrix(rowPort: 3, dataPort: 4);
      for (final (port, value) in matrix.replay()) {
        copy.write(port, value);
      }
      expect(copy.rows, matrix.rows);
      expect(copy.selectedRow, 5);
    });

    test('a fresh device replays to itself', () {
      final io = IoPorts.standard();
      final copy = IoPorts.standard();
      for (final (port, value) in io.replay()) {
        copy.write(port, value);
      }
      expect(lcdView(copy.device<TextLcd>()!), lcdView(io.device<TextLcd>()!));
    });
  });

  group('bridge', () {
    test('shakes hands, then resets the board and replays the state', () async {
      final cpu = runProgram('LCD: Hello, world');
      final bridge = HardwareBridge(cpu);
      final link = FakeLink(answerHelloAfter: 2);
      await bridge.connect(link);
      expect(bridge.status, BridgeStatus.connected);
      expect(bridge.board!.board, 'fake');
      await settle();
      final writes = link.writes;
      expect(writes.first, 'RESET');
      expect(
        writes[1],
        'W 00 ${cpu.outputRegister.toRadixString(16).padLeft(2, '0').toUpperCase()}',
      );
      expect(writes.length, 2 + cpu.io.replay().length);
      expect(link.sent.where((l) => l == 'HELLO 1').length, 2);
      expect(bridge.inFlight, 0);
    });

    test('mirrors port writes as the program runs', () async {
      final cpu = Cpu(mode: extended)
        ..load(
          Assembler(
            mode: extended,
          ).assemble('LDI 0x0C\nOUT 1\nLDI 65\nOUT 2\nOUT\nHLT'),
        );
      final link = FakeLink();
      await HardwareBridge(cpu).connect(link);
      await settle();
      link.sent.clear();
      while (!cpu.halted) {
        cpu.stepInstruction();
      }
      await settle();
      expect(link.sent, ['W 01 0C', 'W 02 41', 'W 00 41']);
    });

    test('never has more lines unanswered than the window', () async {
      final cpu = runProgram('LCD: Hello, world');
      final link = FakeLink(window: 3, autoAck: false);
      final bridge = HardwareBridge(cpu);
      await bridge.connect(link);
      await settle();
      expect(bridge.inFlight, 3);
      expect(link.unanswered, 3);
      final total = 2 + cpu.io.replay().length;
      while (link.writes.length < total || link.unanswered > 0) {
        link.ackAll();
        await settle();
      }
      expect(link.maxInFlight, 3);
      expect(link.writes.length, total);
      expect(bridge.queued, 0);
    });

    test('resyncs after a step back', () async {
      final cpu = Cpu(mode: extended)
        ..load(
          Assembler(
            mode: extended,
          ).assemble('LDI 0x0C\nOUT 1\nLDI 65\nOUT 2\nHLT'),
        );
      final before = cpu.snapshot();
      final link = FakeLink();
      await HardwareBridge(cpu).connect(link);
      while (!cpu.halted) {
        cpu.stepInstruction();
      }
      await settle();
      link.sent.clear();
      cpu.restore(before);
      cpu.restore(before); // several step-backs in a row: one resync
      await settle();
      expect(link.sent.where((l) => l == 'RESET').length, 1);
      expect(link.sent, isNot(contains('W 02 41')));
    });

    test('a key pressed on the board reaches the keypad', () async {
      final cpu = Cpu(mode: extended);
      var changes = 0;
      final bridge = HardwareBridge(cpu, onChange: () => changes++);
      final link = FakeLink();
      await bridge.connect(link);
      changes = 0;
      link.reply('K 37\nK 99\n');
      await settle();
      expect(cpu.io.device<Keypad>()!.pending, 0x37);
      expect(changes, greaterThan(0));
      expect(bridge.log.last, contains('not on the keypad'));
    });

    test('gives up when the board never answers HELLO', () async {
      final link = FakeLink(answerHelloAfter: 1000);
      final bridge = HardwareBridge(
        Cpu(mode: extended),
        helloTimeout: const Duration(milliseconds: 100),
        helloRetry: const Duration(milliseconds: 30),
      );
      await expectLater(bridge.connect(link), throwsA(isA<TimeoutException>()));
      expect(bridge.status, BridgeStatus.disconnected);
      expect(bridge.error, contains('No answer'));
      expect(link.closed, isTrue);
    });

    test('refuses a board speaking another protocol version', () async {
      final link = FakeLink(hello: 'GLASSBOX 2 future lcd');
      final bridge = HardwareBridge(Cpu(mode: extended));
      await expectLater(bridge.connect(link), throwsA(isA<StateError>()));
      expect(bridge.error, contains('protocol 2'));
    });

    test('resends the state when acks stop coming', () async {
      final cpu = Cpu(mode: extended);
      final link = FakeLink(autoAck: false);
      final bridge = HardwareBridge(
        cpu,
        ackTimeout: const Duration(milliseconds: 50),
      );
      await bridge.connect(link);
      await settle();
      final first = link.sent.where((l) => l == 'RESET').length;
      await Future.delayed(const Duration(milliseconds: 120));
      expect(link.sent.where((l) => l == 'RESET').length, greaterThan(first));
      expect(bridge.log.any((l) => l.contains('No answer')), isTrue);
    });

    test('stops mirroring once disconnected, or when the link drops', () async {
      final cpu = Cpu(mode: extended);
      final bridge = HardwareBridge(cpu);
      final link = FakeLink();
      await bridge.connect(link);
      await bridge.disconnect();
      expect(link.closed, isTrue);
      final count = link.sent.length;
      cpu.io.write(2, 0x41);
      await settle();
      expect(link.sent.length, count);

      final link2 = FakeLink();
      await bridge.connect(link2);
      await link2._received.close();
      await settle();
      expect(bridge.status, BridgeStatus.disconnected);
      expect(bridge.error, contains('closed'));
    });
  });
}
