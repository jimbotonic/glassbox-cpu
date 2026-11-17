import '../l10n/app_strings.dart';

/// The two machines the simulator can be.
///
/// * [classic]: the original breadboard computer. 16 bytes of RAM, one-byte
///   instructions with a 4-bit opcode and a 4-bit operand.
/// * [extended]: the same bus and fetch cycle, widened. 256 bytes of RAM,
///   a whole opcode byte followed by an 8-bit operand byte when needed,
///   more ALU operations, a stack and indexed loads.
enum CpuMode {
  classic(ramSize: 16),
  extended(ramSize: 256);

  final int ramSize;

  const CpuMode({required this.ramSize});

  /// Name in the current language, e.g. `Classic`.
  String get label => this == classic ? tApp.classicLabel : tApp.extendedLabel;

  /// One-line summary in the current language, e.g. `16 bytes of RAM, …`.
  String get description =>
      this == classic ? tApp.classicDescription : tApp.extendedDescription;

  /// Mask applied to addresses (PC, MAR, SP): 0xF or 0xFF.
  int get addressMask => ramSize - 1;

  /// Bits in an address: 4 or 8.
  int get addressBits => this == classic ? 4 : 8;

  /// Hex digits needed to show an address: 1 or 2.
  int get addressDigits => this == classic ? 1 : 2;

  /// [address] in hex at this mode's width, e.g. `0xE` or `0x0E`.
  String hexAddress(int address) =>
      '0x${(address & addressMask).toRadixString(16).toUpperCase().padLeft(addressDigits, '0')}';
}
