import 'cpu_mode.dart';
import 'opcode.dart';

class Disassembler {
  /// Text of the instruction whose opcode is [byte]. In Extended mode the
  /// operand is a separate byte; pass it as [operand], or leave it out to
  /// get the mnemonic and operand kind only, e.g. `LDA addr`.
  static String disassemble(
    int byte, {
    CpuMode mode = CpuMode.classic,
    int? operand,
  }) {
    final opcode = Opcode.decode(byte, mode);
    final value = mode == CpuMode.classic ? byte & 0xF : operand;
    return switch (opcode.operand) {
      OperandKind.none => opcode.mnemonic,
      OperandKind.indexedB => opcode.usage,
      _ when value == null => opcode.usage,
      OperandKind.immediate => '${opcode.mnemonic} #$value',
      OperandKind.address => '${opcode.mnemonic} ${mode.hexAddress(value)}',
    };
  }

  /// One line per RAM byte, decoding from address 0 the way the CPU would
  /// if it ran straight through: in Extended mode the byte after an opcode
  /// that takes a value is shown as that opcode's operand. Data placed
  /// after the code decodes as instructions too, as it would on the
  /// breadboard.
  static List<String> sweep(List<int> ram, {CpuMode mode = CpuMode.classic}) {
    final lines = List.filled(ram.length, '');
    int a = 0;
    while (a < ram.length) {
      final opcode = Opcode.decode(ram[a], mode);
      final size = opcode.sizeIn(mode);
      if (size == 2 && a + 1 < ram.length) {
        lines[a] = disassemble(ram[a], mode: mode, operand: ram[a + 1]);
        lines[a + 1] = '  ↳ operand';
      } else {
        lines[a] = disassemble(ram[a], mode: mode);
      }
      a += size;
    }
    return lines;
  }

  static List<String> disassembleProgram(
    List<int> ram, {
    CpuMode mode = CpuMode.classic,
  }) => sweep(ram, mode: mode);
}
