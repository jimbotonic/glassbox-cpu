import 'package:flutter_8_bit_cpu_simulator/core/assembler.dart';
import 'package:flutter_8_bit_cpu_simulator/core/builtin_program_list.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu_mode.dart';
import 'package:flutter_8_bit_cpu_simulator/core/disassembler.dart';
import 'package:flutter_8_bit_cpu_simulator/core/io/io_ports.dart';
import 'package:flutter_8_bit_cpu_simulator/core/io/keypad.dart';
import 'package:flutter_8_bit_cpu_simulator/core/io/led_matrix.dart';
import 'package:flutter_8_bit_cpu_simulator/core/io/text_lcd.dart';
import 'package:flutter_8_bit_cpu_simulator/core/microcode.dart';
import 'package:flutter_8_bit_cpu_simulator/core/step_info.dart';
import 'package:flutter_test/flutter_test.dart';

const extended = CpuMode.extended;

Cpu cpuWith(String source) =>
    Cpu(mode: extended)..load(Assembler(mode: extended).assemble(source));

TextLcd lcdOf(Cpu cpu) => cpu.io.device<TextLcd>()!;
LedMatrix matrixOf(Cpu cpu) => cpu.io.device<LedMatrix>()!;
Keypad keypadOf(Cpu cpu) => cpu.io.device<Keypad>()!;

String lcdLine(TextLcd lcd, int row) => String.fromCharCodes([
  for (int c = 0; c < TextLcd.columns; c++) lcd.charAt(row, c),
]);

void main() {
  group('assembler', () {
    final asm = Assembler(mode: extended);

    test('OUT picks its form by the operand', () {
      expect(asm.assemble('OUT'), [0x0E]);
      expect(asm.assemble('OUT 2'), [0x18, 0x02]);
      expect(asm.assemble('IN 5'), [0x19, 0x05]);
      expect(asm.assemble('.equ LCD 2\nOUT LCD'), [0x18, 0x02]);
    });

    test('ports are 0-255 and IN needs one', () {
      expect(
        () => asm.assemble('OUT 256'),
        throwsA(
          isA<AssemblerError>().having(
            (e) => e.message,
            'message',
            contains('Port must be 0-255'),
          ),
        ),
      );
      expect(() => asm.assemble('IN'), throwsA(isA<AssemblerError>()));
    });

    test('Classic keeps plain OUT and rejects ports', () {
      final classic = Assembler();
      expect(classic.assemble('OUT'), [0xE0]);
      expect(
        () => classic.assemble('OUT 1'),
        throwsA(
          isA<AssemblerError>().having(
            (e) => e.message,
            'message',
            contains('Extended'),
          ),
        ),
      );
    });

    test('disassembles port instructions', () {
      expect(
        Disassembler.disassemble(0x18, mode: extended, operand: 3),
        'OUT 3',
      );
      expect(Disassembler.sweep([0x19, 5, 0x0F], mode: extended), [
        'IN 5',
        '  ↳ operand',
        'HLT',
      ]);
    });
  });

  group('cpu', () {
    test('OUT port runs PI then DI', () {
      final cpu = cpuWith('LDI 0x41\nOUT 2\nHLT');
      cpu.stepInstruction(); // LDI
      final words = <String>[];
      do {
        cpu.tick();
        words.add(Microcode.describe(cpu.controlWord));
      } while (cpu.microStep != 0);
      expect(words, ['MI|CO', 'RO|II|CE', 'MI|CO', 'RO|CE|PI', 'AO|DI']);
      expect(cpu.portRegister, 2);
      expect(lcdOf(cpu).charAt(0, 0), 0x41);
    });

    test('OUT 0 and plain OUT both feed the display', () {
      final outputs = <int>[];
      final cpu = cpuWith('LDI 7\nOUT\nLDI 9\nOUT 0\nHLT')
        ..onOutput = outputs.add;
      cpu.run();
      expect(outputs, [7, 9]);
      expect(cpu.outputRegister, 9);
    });

    test('IN reads a device into A without touching the flags', () {
      final cpu = cpuWith('IN 5\nHLT');
      keypadOf(cpu).press('7');
      cpu.zeroFlag = true;
      cpu.run();
      expect(cpu.registerA, '7'.codeUnitAt(0));
      expect(cpu.zeroFlag, isTrue);
      expect(keypadOf(cpu).pending, isNull, reason: 'read once');
    });

    test('an unconnected port reads 0', () {
      final cpu = cpuWith('LDI 1\nIN 200\nHLT')..run();
      expect(cpu.registerA, 0);
    });

    test('listeners see every port write, port 0 included', () {
      final writes = <(int, int)>[];
      final cpu = cpuWith('LDI 3\nOUT\nOUT 4\nHLT');
      cpu.io.addListener((p, v) => writes.add((p, v)));
      cpu.run();
      expect(writes, [(0, 3), (4, 3)]);
    });

    test('step-back restores device state', () {
      final cpu = cpuWith('LDI 0x38\nOUT 3\nLDI 0xFF\nOUT 4\nHLT');
      cpu.stepInstruction();
      cpu.stepInstruction();
      cpu.stepInstruction();
      final before = cpu.snapshot();
      cpu.stepInstruction(); // lights a row
      expect(matrixOf(cpu).rows, isNot(everyElement(0)));
      cpu.restore(before);
      expect(matrixOf(cpu).rows, everyElement(0));
      expect(cpu.portRegister, 3);
    });

    test('reset powers the devices off', () {
      final cpu = cpuWith('LDI 0x0C\nOUT 1\nHLT')..run();
      expect(lcdOf(cpu).displayOn, isTrue);
      cpu.reset();
      expect(lcdOf(cpu).displayOn, isFalse);
    });

    test('step info names the port', () {
      final cpu = cpuWith('LDI 0x41\nOUT 2\nIN 5\nHLT');
      cpu.stepInstruction();
      for (int i = 0; i < 5; i++) {
        cpu.tick();
      }
      var info = StepInfo.of(cpu);
      expect(info.purpose, 'OUT 2');
      expect(info.destinationLabels, ['port 2 (LCD data)']);
      expect(info.source, BusNode.registerA);
      for (int i = 0; i < 5; i++) {
        cpu.tick();
      }
      info = StepInfo.of(cpu);
      expect(info.source, BusNode.device);
      expect(info.sourceLabel, 'port 5 (keypad)');
    });
  });

  group('text LCD', () {
    late TextLcd lcd;
    setUp(() => lcd = TextLcd(commandPort: 1, dataPort: 2));
    void cmd(int v) => lcd.write(1, v);
    void text(String s) {
      for (final c in s.codeUnits) {
        lcd.write(2, c);
      }
    }

    test('is off after power-on', () {
      expect(lcd.displayOn, isFalse);
      cmd(0x0E);
      expect(lcd.displayOn, isTrue);
      expect(lcd.cursorOn, isTrue);
      expect(lcd.blinkOn, isFalse);
    });

    test('writes move the cursor; 0xC0 starts line 2', () {
      text('HI');
      cmd(0xC0);
      text('YO');
      expect(lcdLine(lcd, 0).trimRight(), 'HI');
      expect(lcdLine(lcd, 1).trimRight(), 'YO');
      expect(lcd.read(1), 0x42, reason: 'address counter');
    });

    test('line 1 continues at line 2 after 40 characters', () {
      text('x' * 40);
      expect(lcd.address, 0x40);
      text('!');
      expect(lcd.charAt(1, 0), 0x21);
    });

    test('clear and home', () {
      text('ABC');
      cmd(0x18); // shift display left
      expect(lcd.displayShift, 1);
      expect(lcd.charAt(0, 0), 0x42);
      cmd(0x02);
      expect(lcd.displayShift, 0);
      expect(lcd.address, 0);
      cmd(0x01);
      expect(lcdLine(lcd, 0), ' ' * 16);
    });

    test('entry mode can move left and shift the display', () {
      cmd(0x85);
      cmd(0x04); // move left
      text('AB');
      expect(lcd.charAt(0, 5), 0x41);
      expect(lcd.charAt(0, 4), 0x42);
      cmd(0x07); // move right, shift display on each write
      text('C');
      expect(lcd.displayShift, 1);
    });

    test('cursor column follows the address and the shift', () {
      cmd(0x83);
      expect(lcd.cursorColumn(0), 3);
      expect(lcd.cursorColumn(1), isNull);
      cmd(0x18);
      expect(lcd.cursorColumn(0), 2);
    });

    test('CGRAM defines custom characters', () {
      cmd(0x48); // character 1, row 0
      for (final row in [0x1F, 0x11, 0x11, 0x11, 0x11, 0x11, 0x1F, 0x00]) {
        lcd.write(2, row);
      }
      expect(lcd.customGlyph(1).first, 0x1F);
      expect(lcd.customGlyph(9), lcd.customGlyph(1), reason: 'mirrored');
      cmd(0x80);
      lcd.write(2, 1);
      expect(lcd.charAt(0, 0), 1);
    });

    test('reading data returns the character and moves on', () {
      text('Q');
      cmd(0x80);
      expect(lcd.peek(2), 0x51);
      expect(lcd.read(2), 0x51);
      expect(lcd.address, 1);
    });
  });

  group('LED matrix and keypad', () {
    test('data bytes fill rows in turn', () {
      final m = LedMatrix(rowPort: 3, dataPort: 4);
      m.write(3, 6);
      m.write(4, 0x81);
      m.write(4, 0xFF);
      expect(m.rows[6], 0x81);
      expect(m.rows[7], 0xFF);
      expect(m.selectedRow, 0);
      expect(m.isLit(6, 0), isTrue);
      expect(m.isLit(6, 1), isFalse);
    });

    test('keypad gives each press once, as ASCII', () {
      final k = Keypad(port: 5);
      expect(k.read(5), 0);
      k.press('#');
      expect(k.peek(5), 0x23);
      expect(k.read(5), 0x23);
      expect(k.read(5), 0);
    });

    test('ports cannot be shared', () {
      expect(
        () => IoPorts([Keypad(port: 1), LedMatrix(rowPort: 1, dataPort: 2)]),
        throwsArgumentError,
      );
    });
  });

  group('built-in device programs', () {
    test('LCD: Hello, world fills both lines', () {
      final cpu = runBuiltin('LCD: Hello, world');
      expect(cpu.halted, isTrue);
      final lcd = lcdOf(cpu);
      expect(lcd.displayOn, isTrue);
      expect(lcdLine(lcd, 0).trimRight(), 'Hello, world!');
      expect(lcdLine(lcd, 1).trimRight(), 'GlassBox CPU');
    });

    test('LCD: custom character draws a heart', () {
      final cpu = runBuiltin('LCD: custom character');
      expect(cpu.halted, isTrue);
      final lcd = lcdOf(cpu);
      expect(lcd.customGlyph(0), [0, 10, 31, 31, 31, 14, 4, 0]);
      expect(
        [for (int c = 0; c < 7; c++) lcd.charAt(0, c)],
        [...'I '.codeUnits, 0, ...' CPU'.codeUnits],
      );
    });

    test('LED matrix: smiley lights eight rows', () {
      final cpu = runBuiltin('LED matrix: smiley');
      expect(cpu.halted, isTrue);
      expect(matrixOf(cpu).rows, [
        0x3C, 0x42, 0xA5, 0x81, 0xA5, 0x99, 0x42, 0x3C, //
      ]);
    });

    test('Keypad echo writes each key once', () {
      final program = BuiltinProgramList.getByName('Keypad echo')!;
      final outputs = <int>[];
      final cpu = cpuWith(program.code)..onOutput = outputs.add;
      cpu.run(maxTicks: 300);
      for (final key in ['4', '2', '#']) {
        keypadOf(cpu).press(key);
        cpu.run(maxTicks: 300);
      }
      expect(cpu.halted, isFalse);
      expect(lcdLine(lcdOf(cpu), 0).trimRight(), '42#');
      expect(outputs, '42#'.codeUnits);
    });
  });
}

/// Runs built-in program [name] until it halts or [maxTicks] pass.
Cpu runBuiltin(String name, {int maxTicks = 20000}) {
  final program = BuiltinProgramList.getByName(name)!;
  final cpu = cpuWith(program.code);
  cpu.run(maxTicks: maxTicks);
  return cpu;
}
