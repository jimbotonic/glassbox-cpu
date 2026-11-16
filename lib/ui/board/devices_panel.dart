import 'package:flutter/material.dart';

import '../../core/control_word.dart';
import '../../core/cpu.dart';
import '../../core/io/io_ports.dart';
import '../../core/io/keypad.dart';
import '../../core/io/led_matrix.dart';
import '../../core/io/text_lcd.dart';
import '../hardware/hardware_controller.dart';
import '../hardware/hardware_dialog.dart';
import '../theme/glass.dart';
import 'glass_widgets.dart';

/// The devices on the I/O ports, drawn as the hardware would look. A card
/// lights up in the bus colours when the CPU writes (DI, orange) or reads
/// (DO, blue) one of its ports.
class DevicesPanel extends StatelessWidget {
  final Cpu cpu;

  /// The user pressed a keypad key.
  final ValueChanged<String> onKey;

  /// The link to a real board mirroring these devices.
  final HardwareController hardware;

  const DevicesPanel({
    super.key,
    required this.cpu,
    required this.onKey,
    required this.hardware,
  });

  /// What [device] does on the bus during the step just executed.
  BusRole _role(IoDevice device) {
    if (cpu.executedStep == null) return BusRole.idle;
    if (!device.ports.contains(cpu.portRegister)) return BusRole.idle;
    if (ControlWord.dout.isActive(cpu.controlWord)) return BusRole.drive;
    if (ControlWord.di.isActive(cpu.controlWord)) return BusRole.read;
    return BusRole.idle;
  }

  @override
  Widget build(BuildContext context) {
    final io = cpu.io;
    final lcd = io.device<TextLcd>();
    final matrix = io.device<LedMatrix>();
    final keypad = io.device<Keypad>();

    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('I/O DEVICES', style: Glass.panelTitle),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'OUT port writes A to a device · IN port reads one into A',
                  style: Glass.note,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              _HardwareButton(hardware: hardware),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (lcd != null)
                _DeviceCard(
                  device: lcd,
                  role: _role(lcd),
                  child: _LcdView(lcd: lcd),
                ),
              if (keypad != null)
                _DeviceCard(
                  device: keypad,
                  role: _role(keypad),
                  child: _KeypadView(keypad: keypad, onKey: onKey),
                ),
              if (matrix != null)
                _DeviceCard(
                  device: matrix,
                  role: _role(matrix),
                  child: _MatrixView(matrix: matrix),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows whether a real board mirrors the devices; opens the dialog.
class _HardwareButton extends StatelessWidget {
  final HardwareController hardware;

  const _HardwareButton({required this.hardware});

  @override
  Widget build(BuildContext context) {
    final bridge = hardware.bridge;
    final connected = hardware.connected;
    final label = connected
        ? 'Board: ${bridge.board!.board}'
        : hardware.busy
        ? 'Connecting…'
        : 'Real hardware';
    return GlassButton(
      label: label,
      height: 32,
      tooltip: connected
          ? 'Mirrored to ${bridge.link!.description}'
          : 'Mirror these devices to an Arduino, ESP32 or Raspberry Pi',
      fill: connected ? Glass.okText.withValues(alpha: 0.12) : null,
      foreground: connected ? Glass.okText : null,
      onPressed: () => showHardwareDialog(context, hardware),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final IoDevice device;
  final BusRole role;
  final Widget child;

  const _DeviceCard({
    required this.device,
    required this.role,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ports = device.ports;
    final portText = ports.length == 1
        ? 'port ${ports.first} · ${device.portName(ports.first)}'
        : 'ports ${ports.join('–')} · '
              '${[for (final p in ports) device.portName(p).split(' ').last].join(', ')}';
    return GlassPanel(
      role: role,
      color: Glass.sunken,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(device.name.toUpperCase(), style: Glass.panelTitle),
                const SizedBox(width: 16),
                const Spacer(),
                RoleLabel(role: role),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              portText,
              style: const TextStyle(fontSize: 11, color: Glass.dim),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ LCD

class _LcdView extends StatelessWidget {
  final TextLcd lcd;

  const _LcdView({required this.lcd});

  static const double _cellW = 17;
  static const double _cellH = 27;
  static const _screenOn = Color(0xFF9DB33A);
  static const _screenOff = Color(0xFF3E471C);
  static const _cellOn = Color(0xFF93A934);
  static const _ink = Color(0xFF1C2608);

  String _status() {
    if (!lcd.displayOn) return 'display off · send 0x0C to turn it on';
    final where = lcd.addressingCgram
        ? 'CGRAM 0x${lcd.address.toRadixString(16).toUpperCase().padLeft(2, '0')}'
        : 'cursor ${Glass.hex2(lcd.address)}';
    return '$where · ${lcd.moveRight ? 'writes go right' : 'writes go left'}'
        '${lcd.displayShift == 0 ? '' : ' · shifted ${lcd.displayShift}'}';
  }

  @override
  Widget build(BuildContext context) {
    final on = lcd.displayOn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label:
              'LCD: ${[
                for (int r = 0; r < TextLcd.rows; r++) String.fromCharCodes([for (int c = 0; c < TextLcd.columns; c++) lcd.charAt(r, c)]).trimRight(),
              ].join(' / ')}',
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF14200E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2B3A1E)),
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: on ? _screenOn : _screenOff,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int r = 0; r < TextLcd.rows; r++)
                    Padding(
                      padding: EdgeInsets.only(top: r == 0 ? 0 : 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int c = 0; c < TextLcd.columns; c++)
                            Padding(
                              padding: EdgeInsets.only(left: c == 0 ? 0 : 2),
                              child: _cell(r, c, on),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _status(),
          style: Glass.code.copyWith(fontSize: 11, color: Glass.muted),
        ),
      ],
    );
  }

  Widget _cell(int row, int column, bool on) {
    final code = lcd.charAt(row, column);
    final cursor = on && lcd.cursorColumn(row) == column;
    Widget? glyph;
    if (on) {
      glyph = code < 0x10
          ? CustomPaint(
              size: const Size(_cellW - 3, _cellH - 6),
              painter: _GlyphPainter(lcd.customGlyph(code), _ink),
            )
          : Text(
              lcdCharacter(code),
              style: const TextStyle(
                fontFamily: Glass.mono,
                fontSize: 17,
                height: 1,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            );
    }
    return Container(
      width: _cellW,
      height: _cellH,
      color: on ? _cellOn : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (cursor && lcd.blinkOn)
            Container(color: _ink.withValues(alpha: 0.75)),
          if (glyph != null) glyph,
          if (cursor && lcd.cursorOn)
            Positioned(
              left: 1,
              right: 1,
              bottom: 1,
              child: Container(height: 2, color: _ink),
            ),
        ],
      ),
    );
  }
}

/// Character of HD44780 code [code] in the common A00 (Japanese) ROM:
/// ASCII from 0x20 to 0x7D, then ¥ for `\`, arrows, katakana and symbols.
/// Codes 0x00-0x0F are custom characters and are drawn from CGRAM.
String lcdCharacter(int code) {
  if (code >= 0x20 && code <= 0x7D) {
    return code == 0x5C ? '¥' : String.fromCharCode(code);
  }
  if (code == 0x7E) return '→';
  if (code == 0x7F) return '←';
  if (code >= 0xA1 && code <= 0xDF) {
    return String.fromCharCode(0xFF61 + code - 0xA1); // half-width kana
  }
  if (code >= 0xE0) return _highCharacters[code - 0xE0];
  return ' ';
}

const List<String> _highCharacters = [
  'α',
  'ä',
  'β',
  'ε',
  'μ',
  'σ',
  'ρ',
  'g',
  '√',
  '⁻',
  'j',
  'ˣ',
  '¢',
  '£',
  'ñ',
  'ö', //
  'p',
  'q',
  'θ',
  '∞',
  'Ω',
  'ü',
  'Σ',
  'π',
  'x',
  'y',
  '千',
  '万',
  '円',
  '÷',
  ' ',
  '█',
];

/// A 5x8 custom character, bit 4 of each row on the left.
class _GlyphPainter extends CustomPainter {
  final List<int> rows;
  final Color color;

  _GlyphPainter(this.rows, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 5;
    final h = size.height / 8;
    final paint = Paint()..color = color;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 5; c++) {
        if ((rows[r] >> (4 - c)) & 1 == 1) {
          canvas.drawRect(
            Rect.fromLTWH(c * w + 0.5, r * h + 0.5, w - 1, h - 1),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.color != color || !_sameRows(old.rows, rows);

  static bool _sameRows(List<int> a, List<int> b) {
    for (int i = 0; i < 8; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ----------------------------------------------------------- LED matrix

class _MatrixView extends StatelessWidget {
  final LedMatrix matrix;

  const _MatrixView({required this.matrix});

  static const double _led = 13;
  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final selected = matrix.selectedRow;
    return Semantics(
      label: 'LED matrix rows: ${matrix.rows.map(Glass.hex2).join(' ')}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 8, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0606),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF3A1A1A)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int r = 0; r < LedMatrix.size; r++)
              Padding(
                padding: EdgeInsets.only(top: r == 0 ? 0 : _gap),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      child: Text(
                        r == selected ? '▸' : '',
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1,
                          color: Glass.bus,
                        ),
                      ),
                    ),
                    for (int c = 0; c < LedMatrix.size; c++)
                      Container(
                        width: _led,
                        height: _led,
                        margin: EdgeInsets.only(left: c == 0 ? 0 : _gap),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: matrix.isLit(r, c)
                              ? Glass.led
                              : const Color(0xFF261515),
                          boxShadow: matrix.isLit(r, c)
                              ? [
                                  BoxShadow(
                                    color: Glass.led.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    const SizedBox(width: 10),
                    Text(
                      Glass.hex2(matrix.rows[r]),
                      style: Glass.code.copyWith(
                        fontSize: 11,
                        height: 1,
                        color: r == selected ? Glass.bus : Glass.dim,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- Keypad

class _KeypadView extends StatelessWidget {
  final Keypad keypad;
  final ValueChanged<String> onKey;

  const _KeypadView({required this.keypad, required this.onKey});

  static const double _key = 44;
  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    final pending = keypad.pending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 4 * _key + 3 * _gap,
          child: Wrap(
            spacing: _gap,
            runSpacing: _gap,
            children: [
              for (final key in Keypad.layout)
                SizedBox(
                  width: _key,
                  child: GlassButton(
                    label: key,
                    height: _key,
                    tooltip:
                        "Press $key: IN reads ${Glass.hex2(key.codeUnitAt(0))}",
                    fill: key.codeUnitAt(0) == pending ? Glass.busGround : null,
                    foreground: key.codeUnitAt(0) == pending ? Glass.bus : null,
                    onPressed: () => onKey(key),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pending == null
              ? 'no key waiting · IN reads 0'
              : "waiting: '${String.fromCharCode(pending)}' · IN reads ${Glass.hex2(pending)}",
          style: Glass.code.copyWith(
            fontSize: 11,
            color: pending == null ? Glass.muted : Glass.bus,
          ),
        ),
      ],
    );
  }
}
