import 'package:flutter/material.dart';

/// Design tokens of the "Signal trace" look: one colour per meaning.
///
/// * [drive] (blue): the module putting a value on the bus this step.
/// * [read] (orange): modules latching the bus on this clock edge.
/// * [bus] (yellow): the bus line, its value and the current source line.
/// * [led] (red): lit bits, the display, breakpoints and halt only.
///
/// Every state also has a text label, so colour is never the only cue.
class Glass {
  Glass._();

  // Surfaces
  static const ground = Color(0xFF0B0D10);
  static const panel = Color(0xFF14171C);
  static const raised = Color(0xFF1A1E24);
  static const sunken = Color(0xFF0F1216);
  static const border = Color(0xFF262B33);
  static const borderSoft = Color(0xFF22262D);

  // Text
  static const text = Color(0xFFE6E8EB);
  static const textSoft = Color(0xFFC9CED4);
  static const muted = Color(0xFF9AA3AE);
  static const dim = Color(0xFF8A939E);
  static const faint = Color(0xFF6F7883);

  // Roles
  static const drive = Color(0xFF3D8BFF);
  static const driveText = Color(0xFF8FC1FF);
  static const driveFill = Color(0xFF1D3A5F);
  static const driveChip = Color(0xFFCFE5FF);
  static const driveRow = Color(0xFF12253D);

  static const read = Color(0xFFFF9F45);
  static const readText = Color(0xFFFFC48A);
  static const readFill = Color(0xFF5A3415);
  static const readChip = Color(0xFFFFE0C2);
  static const readRow = Color(0xFF3A2510);

  static const count = Color(0xFFE7D27A);

  static const bus = Color(0xFFF5C451);
  static const busGround = Color(0xFF17150E);
  static const busBorder = Color(0xFF4A3F1C);
  static const busMuted = Color(0xFFB9AD86);

  static const led = Color(0xFFFF5C5C);
  static const ledOff = Color(0xFF232830);
  static const ledOffBorder = Color(0xFF333A44);

  static const ok = Color(0xFF2F9E6B);
  static const okText = Color(0xFF7FD6A8);

  // Code syntax
  static const synLabel = Color(0xFFE8C27A);
  static const synOp = Color(0xFF8FC1FF);
  static const synArg = Color(0xFFC3E88D);
  static const synComment = Color(0xFF7E8893);
  static const synData = Color(0xFF9ED3C6);

  /// Monospaced family for values, code and signals.
  static const mono = 'GoogleSansCode';

  static const radius = 10.0;

  static const TextStyle panelTitle = TextStyle(
    color: text,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.7,
  );

  static const TextStyle note = TextStyle(color: muted, fontSize: 12);

  static const TextStyle dialogTitle = TextStyle(
    color: text,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  /// Heading of a group inside a panel or dialog.
  static const TextStyle sectionTitle = TextStyle(
    color: textSoft,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static const TextStyle value = TextStyle(
    fontFamily: mono,
    color: text,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle code = TextStyle(
    fontFamily: mono,
    color: textSoft,
    fontSize: 12,
  );

  static String hex2(int v) =>
      '0x${(v & 0xFF).toRadixString(16).toUpperCase().padLeft(2, '0')}';

  /// `'E'` for a printable ASCII byte, else null.
  static String? char(int v) =>
      v >= 0x20 && v < 0x7F ? "'${String.fromCharCode(v)}'" : null;
}

/// What a module does on the bus during the current step.
enum BusRole { idle, drive, read, count }
