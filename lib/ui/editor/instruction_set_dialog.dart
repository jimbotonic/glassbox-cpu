import 'package:flutter/material.dart';

import '../../core/cpu_mode.dart';

class InstructionSetDialog extends StatelessWidget {
  /// Machine in use; Extended mode adds its section first.
  final CpuMode mode;

  const InstructionSetDialog({super.key, this.mode = CpuMode.classic});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      constraints: const BoxConstraints(maxHeight: 700),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'INSTRUCTION SET REFERENCE',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Complete guide to all available opcodes and operand types',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mode == CpuMode.extended) ...[
                    _buildExtendedSection(),
                    const SizedBox(height: 20),
                    Text(
                      'CLASSIC INSTRUCTIONS (ALSO IN EXTENDED, WITH 8-BIT '
                      'OPERANDS: ADDRESSES 0-255, VALUES -128..255)',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildOperandTypesSection(),
                  const SizedBox(height: 20),
                  _buildInstructionsSection(),
                  const SizedBox(height: 20),
                  const _SyntaxSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtendedSection() {
    const addr = 'Address (0-255), operand byte';
    const imm = 'Value (-128..255), operand byte';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.cyan.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(4),
            color: Colors.cyan.withValues(alpha: 0.06),
          ),
          child: Text(
            'EXTENDED CPU: 256 bytes of RAM. An instruction is an opcode '
            'byte, followed by an operand byte when it takes an address or '
            'a value; the CPU reads that byte at the program counter '
            '(CO|MI, then RO|..|CE). Names ending in I take a value, the '
            'others an address. The ALU always works on A and B, so ADD, '
            'SUB, AND, OR, XOR, CMP, ADI and SBI overwrite B. The stack '
            'grows down from 0xFF; keep code and data below it.',
            style: TextStyle(color: Colors.grey[300], fontSize: 11),
          ),
        ),
        const SizedBox(height: 16),
        _buildInstructionCategory('EXTENDED: DATA MOVEMENT', Colors.blue, [
          const _InstructionInfo(
            mnemonic: 'LDB',
            hex: '0x0B',
            usage: 'LDB addr',
            color: Colors.blue,
            description: 'Load B - Loads value from RAM into B register.',
            behavior:
                'Reads RAM[addr] into B. Use it to set the index for LDA [B].',
            operandType: addr,
            example: 'LDB ptr ; B = RAM[ptr]',
          ),
          const _InstructionInfo(
            mnemonic: 'LDA [B]',
            hex: '0x30',
            usage: 'LDA [B]',
            color: Colors.blue,
            description: 'Indexed load - Loads from the address held in B.',
            behavior:
                'B drives the bus into MAR (BO|MI), then RAM goes into A '
                '(RO|AI). Walks arrays and strings. One byte, no operand.',
            operandType: 'None ([B] is written in the source)',
            example: 'LDA [B] ; A = RAM[B]',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory('EXTENDED: ALU', Colors.teal, [
          const _InstructionInfo(
            mnemonic: 'ADI',
            hex: '0x0C',
            usage: 'ADI #val',
            color: Colors.teal,
            description: 'Add Immediate - A = A + val.',
            behavior: 'The value goes into B, then A + B into A. Sets C and Z.',
            operandType: imm,
            example: 'ADI 1 ; A = A + 1',
          ),
          const _InstructionInfo(
            mnemonic: 'SBI',
            hex: '0x0D',
            usage: 'SBI #val',
            color: Colors.teal,
            description: 'Subtract Immediate - A = A - val.',
            behavior: 'Like ADI, subtracting. C is set on a borrow.',
            operandType: imm,
            example: 'SBI 1 ; A = A - 1',
          ),
          const _InstructionInfo(
            mnemonic: 'AND / OR / XOR',
            hex: '0x10-0x12',
            usage: 'AND addr',
            color: Colors.teal,
            description: 'Bitwise logic - A = A op RAM[addr].',
            behavior: 'Bit by bit on A and B. Clears C, sets Z.',
            operandType: addr,
            example: 'AND mask ; keep the bits set in RAM[mask]',
          ),
          const _InstructionInfo(
            mnemonic: 'CMP',
            hex: '0x13',
            usage: 'CMP addr',
            color: Colors.teal,
            description: 'Compare - Computes A - RAM[addr] for the flags only.',
            behavior:
                'A is unchanged. Z = 1 when equal; C = 1 when A is smaller.',
            operandType: addr,
            example: 'CMP limit ; then JZ / JC / JNZ / JNC',
          ),
          const _InstructionInfo(
            mnemonic: 'SHL / SHR',
            hex: '0x14 / 0x15',
            usage: 'SHL',
            color: Colors.teal,
            description: 'Shift A left or right by one bit.',
            behavior:
                'The bit shifted out goes into C; a 0 comes in. SHL doubles, '
                'SHR halves.',
            operandType: 'None',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory('EXTENDED: JUMPS & STACK', Colors.orange, [
          const _InstructionInfo(
            mnemonic: 'JNZ / JNC',
            hex: '0x0A / 0x09',
            usage: 'JNZ addr',
            color: Colors.orange,
            description: 'Jump if Not Zero / Not Carry.',
            behavior:
                'Jumps when the flag is 0. Otherwise one step (CE) skips the '
                'operand byte.',
            operandType: addr,
            example: 'JNZ loop',
          ),
          const _InstructionInfo(
            mnemonic: 'PUSH / POP',
            hex: '0x20 / 0x21',
            usage: 'PUSH',
            color: Colors.orange,
            description: 'Save A on the stack / restore it.',
            behavior:
                'PUSH writes A at RAM[SP] then SP = SP - 1. POP does SP = SP '
                '+ 1 then A = RAM[SP]. Last in, first out.',
            operandType: 'None',
          ),
          const _InstructionInfo(
            mnemonic: 'CALL',
            hex: '0x22',
            usage: 'CALL addr',
            color: Colors.orange,
            description: 'Call a subroutine.',
            behavior:
                'Pushes PC (the address of its own operand byte), then jumps '
                'to addr.',
            operandType: addr,
            example: 'CALL multiply',
          ),
          const _InstructionInfo(
            mnemonic: 'RET',
            hex: '0x23',
            usage: 'RET',
            color: Colors.orange,
            description: 'Return from a subroutine.',
            behavior:
                'Pops the saved PC, then steps past the CALL\'s operand byte '
                '(CE), landing on the instruction after the CALL.',
            operandType: 'None',
          ),
        ]),
      ],
    );
  }

  Widget _buildOperandTypesSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OPERAND TYPES',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        _OperandTypeCard(
          prefix: '#',
          name: 'Immediate Value',
          color: Color(0xFFB5CEA8),
          example: 'LDI #5',
          description:
              'A literal value (0-15) loaded directly into the register. '
              'Does NOT access memory - the value itself is used.',
        ),
        SizedBox(height: 6),
        _OperandTypeCard(
          prefix: '0x',
          name: 'Hexadecimal Address',
          color: Color(0xFFB5CEA8),
          example: 'LDA 0xE',
          description:
              'A memory address in hexadecimal format (0x0-0xF). '
              'Accesses the value stored at that RAM location.',
        ),
        SizedBox(height: 6),
        _OperandTypeCard(
          prefix: '',
          name: 'Decimal Address',
          color: Color(0xFFD4D4AA),
          example: 'LDA 14',
          description:
              'A memory address in decimal format (0-15). '
              'Accesses the value stored at that RAM location. Same as hex, just different notation.',
        ),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInstructionCategory('CONTROL FLOW', Colors.grey, [
          const _InstructionInfo(
            mnemonic: 'NOP',
            hex: '0x0',
            usage: 'NOP',
            color: Colors.grey,
            description: 'No Operation - Does nothing, uses one clock cycle.',
            behavior:
                'The program counter increments but no data is moved or modified.',
            operandType: 'None',
          ),
          const _InstructionInfo(
            mnemonic: 'HLT',
            hex: '0xF',
            usage: 'HLT',
            color: Colors.red,
            description: 'Halt - Stops program execution.',
            behavior:
                'The clock stops and the CPU enters a halted state. No further instructions execute.',
            operandType: 'None',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory('DATA MOVEMENT', Colors.blue, [
          const _InstructionInfo(
            mnemonic: 'LDA',
            hex: '0x1',
            usage: 'LDA addr',
            color: Colors.blue,
            description:
                'Load from Address - Loads value from RAM into A register.',
            behavior:
                'Reads the value at the specified memory address and stores it in register A. '
                'Previous A register value is overwritten.',
            operandType: 'Address (0x0-0xF or 0-15)',
            example: 'LDA 0xE ; Load value from RAM[14] into A',
          ),
          const _InstructionInfo(
            mnemonic: 'LDI',
            hex: '0x5',
            usage: 'LDI #val',
            color: Colors.blue,
            description:
                'Load Immediate - Loads a literal value into A register.',
            behavior:
                'Stores the immediate value directly into register A. '
                'Does NOT access memory - the operand IS the value.',
            operandType: 'Immediate value (#0-#15)',
            example: 'LDI #7 ; Load the number 7 into A',
          ),
          const _InstructionInfo(
            mnemonic: 'STA',
            hex: '0x4',
            usage: 'STA addr',
            color: Colors.blue,
            description: 'Store to Address - Stores A register value into RAM.',
            behavior:
                'Writes the current value of register A to the specified memory address. '
                'A register value remains unchanged.',
            operandType: 'Address (0x0-0xF or 0-15)',
            example: 'STA 0xD ; Store A register value to RAM[13]',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory('ARITHMETIC', Colors.teal, [
          const _InstructionInfo(
            mnemonic: 'ADD',
            hex: '0x2',
            usage: 'ADD addr',
            color: Colors.teal,
            description: 'Add - Adds value from RAM to A register.',
            behavior:
                'Reads value from memory address, adds it to register A, stores result in A. '
                'Sets carry flag if result > 255. Sets zero flag if result = 0.',
            operandType: 'Address (0x0-0xF or 0-15)',
            example: 'ADD 0xF ; A = A + RAM[15]',
          ),
          const _InstructionInfo(
            mnemonic: 'SUB',
            hex: '0x3',
            usage: 'SUB addr',
            color: Colors.teal,
            description: 'Subtract - Subtracts value from RAM from A register.',
            behavior:
                'Reads value from memory address, subtracts it from register A, stores result in A. '
                'Sets carry flag if underflow (result < 0). Sets zero flag if result = 0.',
            operandType: 'Address (0x0-0xF or 0-15)',
            example: 'SUB 14 ; A = A - RAM[14]',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory('JUMPS & BRANCHES', Colors.orange, [
          const _InstructionInfo(
            mnemonic: 'JMP',
            hex: '0x6',
            usage: 'JMP addr',
            color: Colors.orange,
            description: 'Jump - Unconditionally jumps to specified address.',
            behavior:
                'Sets the program counter to the operand address. Execution continues from that address. '
                'Used for loops and function calls.',
            operandType: 'Address (0x0-0xF or 0-15)',
            example: 'JMP 0 ; Jump back to start of program',
          ),
          const _InstructionInfo(
            mnemonic: 'JC',
            hex: '0x7',
            usage: 'JC addr',
            color: Colors.orange,
            description: 'Jump if Carry - Jumps only if carry flag is set.',
            behavior:
                'If carry flag = 1, sets program counter to operand address. '
                'Otherwise, continues to next instruction. Used for overflow detection.',
            operandType: 'Address (0x0-0xF or 0-15)',
            example: 'JC 8 ; Jump to address 8 if overflow occurred',
          ),
          const _InstructionInfo(
            mnemonic: 'JZ',
            hex: '0x8',
            usage: 'JZ addr',
            color: Colors.orange,
            description: 'Jump if Zero - Jumps only if zero flag is set.',
            behavior:
                'If zero flag = 1 (last ALU result was 0), sets program counter to operand address. '
                'Otherwise, continues to next instruction. Used for conditional logic.',
            operandType: 'Address (0x0-0xF or 0-15)',
            example: 'JZ 10 ; Jump to address 10 if A = 0',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory('OUTPUT', Colors.purpleAccent, [
          const _InstructionInfo(
            mnemonic: 'OUT',
            hex: '0xE',
            usage: 'OUT',
            color: Colors.purpleAccent,
            description: 'Output - Displays value from A register.',
            behavior:
                'Sends the current value of register A to the output display. '
                'A register value remains unchanged.',
            operandType: 'None',
          ),
        ]),
      ],
    );
  }

  Widget _buildInstructionCategory(
    String name,
    Color color,
    List<_InstructionInfo> instructions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...instructions.map(
          (info) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _InstructionCard(info: info),
          ),
        ),
      ],
    );
  }
}

class _InstructionInfo {
  final String mnemonic;
  final String hex;
  final String usage;
  final Color color;
  final String description;
  final String behavior;
  final String operandType;
  final String? example;

  const _InstructionInfo({
    required this.mnemonic,
    required this.hex,
    required this.usage,
    required this.color,
    required this.description,
    required this.behavior,
    required this.operandType,
    this.example,
  });
}

class _InstructionCard extends StatelessWidget {
  final _InstructionInfo info;

  const _InstructionCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: info.color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
        color: info.color.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  info.mnemonic,
                  style: TextStyle(
                    color: info.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                info.hex,
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
              const Spacer(),
              Text(
                info.usage,
                style: TextStyle(
                  color: info.color.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            info.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          _buildInfoRow('Operand', info.operandType),
          const SizedBox(height: 4),
          Text(
            info.behavior,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              height: 1.4,
            ),
          ),
          if (info.example != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                info.example!,
                style: TextStyle(color: Colors.grey[300], fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: Color(0xFFB5CEA8), fontSize: 10),
        ),
      ],
    );
  }
}

class _OperandTypeCard extends StatelessWidget {
  final String prefix;
  final String name;
  final Color color;
  final String example;
  final String description;

  const _OperandTypeCard({
    required this.prefix,
    required this.name,
    required this.color,
    required this.example,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (prefix.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    prefix,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '(no prefix)',
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                example,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Labels, `.equ` constants and `.db` data, with a worked example.
class _SyntaxSection extends StatelessWidget {
  const _SyntaxSection();

  static const _example =
      '.equ STEP 1       ; constant: a name for a number\n'
      'loop: LDA n       ; label: a name for an address\n'
      '      OUT\n'
      '      SUB step    ; names work wherever a number does\n'
      '      STA n\n'
      '      JZ  done    ; jump forward to a label\n'
      '      JMP loop\n'
      'done: HLT\n'
      'n:    .db 5       ; data: one byte per value\n'
      'step: .db STEP';

  static const _rules = [
    ('label:', 'Names the address of the next byte. Use it as an operand.'),
    ('.equ NAME value', 'Defines a constant. Takes no space in RAM.'),
    (
      '.db 1, 0x2A, \'A\', "HI"',
      'Places bytes (0-255) in RAM: numbers, characters, strings, labels.',
    ),
    ('0x1F  0b101  \'A\'', 'Hex, binary and character literals.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LABELS, CONSTANTS & DATA',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (final (syntax, meaning) in _rules)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 170,
                  child: Text(
                    syntax,
                    style: const TextStyle(
                      color: Color(0xFF4EC9B0),
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    meaning,
                    style: TextStyle(color: Colors.grey[300], fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            _example,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'The gutter lists each line\'s address and assembled byte after '
          'ASSEMBLE & LOAD. Names are not case-sensitive.',
          style: TextStyle(color: Colors.grey[500], fontSize: 10),
        ),
      ],
    );
  }
}
