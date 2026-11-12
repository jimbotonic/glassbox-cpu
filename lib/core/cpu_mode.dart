/// The two machines the simulator can be.
///
/// * [classic]: the original breadboard computer. 16 bytes of RAM, one-byte
///   instructions with a 4-bit opcode and a 4-bit operand.
/// * [extended]: the same bus and fetch cycle, widened. 256 bytes of RAM,
///   a whole opcode byte followed by an 8-bit operand byte when needed,
///   more ALU operations, a stack and indexed loads.
enum CpuMode {
  classic(
    'Classic',
    ramSize: 16,
    description: '16 bytes of RAM, 4-bit operands, 11 instructions',
  ),
  extended(
    'Extended',
    ramSize: 256,
    description: '256 bytes of RAM, 8-bit operands, stack, 27 instructions',
  );

  final String label;
  final int ramSize;
  final String description;

  const CpuMode(this.label, {required this.ramSize, required this.description});

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
