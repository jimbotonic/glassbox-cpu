import 'package:flutter/material.dart';

import 'cpu_mode.dart';

/// What follows the mnemonic in the source, and, in Extended mode, what
/// the operand byte after the opcode byte holds.
enum OperandKind {
  /// No operand: `OUT`.
  none,

  /// A RAM address: `LDA addr`.
  address,

  /// A literal value: `LDI #val`.
  immediate,

  /// The address held in register B: `LDA [B]`. No operand byte.
  indexedB,
}

/// Every instruction of both machines.
///
/// [classic] is the 4-bit opcode in the high nibble of a Classic
/// instruction, or null if the instruction is Extended only. [extended] is
/// the whole opcode byte in Extended mode. The original eleven keep their
/// Classic number, so `LDA` is 0x1 in Classic and 0x01 in Extended.
enum Opcode {
  nop(
    'NOP',
    usage: 'NOP',
    classic: 0x0,
    extended: 0x00,
    highlightColor: OpcodeHighlightColor.grey,
  ),
  lda(
    'LDA',
    usage: 'LDA addr',
    classic: 0x1,
    extended: 0x01,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.blue,
  ),
  add(
    'ADD',
    usage: 'ADD addr',
    classic: 0x2,
    extended: 0x02,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.green,
  ),
  sub(
    'SUB',
    usage: 'SUB addr',
    classic: 0x3,
    extended: 0x03,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.green,
  ),
  sta(
    'STA',
    usage: 'STA addr',
    classic: 0x4,
    extended: 0x04,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.blue,
  ),
  ldi(
    'LDI',
    usage: 'LDI #val',
    classic: 0x5,
    extended: 0x05,
    operand: OperandKind.immediate,
    highlightColor: OpcodeHighlightColor.blue,
  ),
  jmp(
    'JMP',
    usage: 'JMP addr',
    classic: 0x6,
    extended: 0x06,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.orange,
  ),
  jc(
    'JC',
    usage: 'JC addr',
    classic: 0x7,
    extended: 0x07,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.orange,
  ),
  jz(
    'JZ',
    usage: 'JZ addr',
    classic: 0x8,
    extended: 0x08,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.orange,
  ),
  out(
    'OUT',
    usage: 'OUT',
    classic: 0xE,
    extended: 0x0E,
    highlightColor: OpcodeHighlightColor.purple,
  ),
  hlt(
    'HLT',
    usage: 'HLT',
    classic: 0xF,
    extended: 0x0F,
    highlightColor: OpcodeHighlightColor.red,
  ),

  // Extended mode only.
  jnc(
    'JNC',
    usage: 'JNC addr',
    extended: 0x09,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.orange,
  ),
  jnz(
    'JNZ',
    usage: 'JNZ addr',
    extended: 0x0A,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.orange,
  ),
  ldb(
    'LDB',
    usage: 'LDB addr',
    extended: 0x0B,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.blue,
  ),
  adi(
    'ADI',
    usage: 'ADI #val',
    extended: 0x0C,
    operand: OperandKind.immediate,
    highlightColor: OpcodeHighlightColor.green,
  ),
  sbi(
    'SBI',
    usage: 'SBI #val',
    extended: 0x0D,
    operand: OperandKind.immediate,
    highlightColor: OpcodeHighlightColor.green,
  ),
  and(
    'AND',
    usage: 'AND addr',
    extended: 0x10,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.green,
  ),
  or(
    'OR',
    usage: 'OR addr',
    extended: 0x11,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.green,
  ),
  xor(
    'XOR',
    usage: 'XOR addr',
    extended: 0x12,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.green,
  ),
  cmp(
    'CMP',
    usage: 'CMP addr',
    extended: 0x13,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.green,
  ),
  shl(
    'SHL',
    usage: 'SHL',
    extended: 0x14,
    highlightColor: OpcodeHighlightColor.green,
  ),
  shr(
    'SHR',
    usage: 'SHR',
    extended: 0x15,
    highlightColor: OpcodeHighlightColor.green,
  ),
  push(
    'PUSH',
    usage: 'PUSH',
    extended: 0x20,
    highlightColor: OpcodeHighlightColor.blue,
  ),
  pop(
    'POP',
    usage: 'POP',
    extended: 0x21,
    highlightColor: OpcodeHighlightColor.blue,
  ),
  call(
    'CALL',
    usage: 'CALL addr',
    extended: 0x22,
    operand: OperandKind.address,
    highlightColor: OpcodeHighlightColor.orange,
  ),
  ret(
    'RET',
    usage: 'RET',
    extended: 0x23,
    highlightColor: OpcodeHighlightColor.orange,
  ),
  ldaIndexed(
    'LDA',
    usage: 'LDA [B]',
    extended: 0x30,
    operand: OperandKind.indexedB,
    highlightColor: OpcodeHighlightColor.blue,
  );

  final String mnemonic;
  final String usage;

  /// 4-bit Classic opcode, or null if the instruction is Extended only.
  final int? classic;

  /// Extended opcode byte.
  final int extended;
  final OperandKind operand;
  final OpcodeHighlightColor highlightColor;

  const Opcode(
    this.mnemonic, {
    required this.usage,
    this.classic,
    required this.extended,
    this.operand = OperandKind.none,
    required this.highlightColor,
  });

  /// Whether the source must give an operand after the mnemonic.
  bool get requiresOperand => operand != OperandKind.none;

  /// Whether the operand is a value or address (as opposed to `[B]`).
  bool get takesValue =>
      operand == OperandKind.address || operand == OperandKind.immediate;

  bool isAvailableIn(CpuMode mode) =>
      mode == CpuMode.extended || classic != null;

  /// Bytes the instruction occupies: always 1 in Classic; in Extended, 2
  /// when an operand byte follows the opcode byte.
  int sizeIn(CpuMode mode) => mode == CpuMode.extended && takesValue ? 2 : 1;

  /// Instructions of [mode], in opcode order.
  static List<Opcode> forMode(CpuMode mode) {
    final list = values.where((op) => op.isAvailableIn(mode)).toList();
    list.sort(
      (a, b) => mode == CpuMode.classic
          ? a.classic!.compareTo(b.classic!)
          : a.extended.compareTo(b.extended),
    );
    return list;
  }

  /// Instruction encoded by [byte] in [mode]; unknown codes run as NOP,
  /// as an empty microcode EEPROM row would.
  static Opcode decode(int byte, CpuMode mode) {
    if (mode == CpuMode.classic) {
      final nibble = (byte >> 4) & 0xF;
      return values.firstWhere(
        (op) => op.classic == nibble,
        orElse: () => Opcode.nop,
      );
    }
    return values.firstWhere(
      (op) => op.extended == (byte & 0xFF),
      orElse: () => Opcode.nop,
    );
  }

  /// Whether [word] is the mnemonic of some instruction, in any mode.
  static bool isMnemonic(String word) {
    final upper = word.toUpperCase();
    return values.any((op) => op.mnemonic == upper);
  }
}

enum OpcodeHighlightColor {
  grey(Color(0xFF7F848E), alpha: 1),
  blue(Color(0xFF82AAFE), alpha: 1),
  green(Color(0xFF17A386), alpha: 1),
  orange(Color(0xFFED8F03), alpha: 1),
  purple(Color(0xFFFF6BCB), alpha: 1),
  red(Color(0xFFD43B30), alpha: 1);

  final Color color;
  final double alpha;
  const OpcodeHighlightColor(this.color, {required this.alpha});
}
