import 'package:flutter/material.dart';

import '../../core/cpu_mode.dart';
import '../board/glass_widgets.dart';
import '../theme/glass.dart';

class InstructionSetDialog extends StatelessWidget {
  /// Machine in use; Extended mode adds its section first.
  final CpuMode mode;

  const InstructionSetDialog({super.key, this.mode = CpuMode.classic});

  @override
  Widget build(BuildContext context) {
    return GlassDialogFrame(
      title: 'INSTRUCTION SET',
      note: mode == CpuMode.extended
          ? 'Every instruction of the Extended CPU, then the Classic ones it '
                'keeps.'
          : 'Every instruction of the Classic CPU, its operand and an '
                'example.',
      width: 640,
      maxHeight: 720,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mode == CpuMode.extended) ...[
            _buildExtendedSection(),
            const SizedBox(height: 20),
            const GlassSectionTitle(
              'Classic instructions, also in Extended with 8-bit operands '
              '(addresses 0-255, values -128..255)',
            ),
            const SizedBox(height: 4),
          ],
          _buildOperandTypesSection(),
          const SizedBox(height: 20),
          _buildInstructionsSection(),
          const SizedBox(height: 20),
          const _SyntaxSection(),
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
            color: Glass.busGround,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Glass.busBorder),
          ),
          child: const Text(
            'EXTENDED CPU: 256 bytes of RAM. An instruction is an opcode '
            'byte, followed by an operand byte when it takes an address or '
            'a value; the CPU reads that byte at the program counter '
            '(CO|MI, then RO|..|CE). Names ending in I take a value, the '
            'others an address. The ALU always works on A and B, so ADD, '
            'SUB, AND, OR, XOR, CMP, ADI and SBI overwrite B. The stack '
            'grows down from 0xFF; keep code and data below it.',
            style: TextStyle(color: Glass.textSoft, fontSize: 12, height: 1.5),
          ),
        ),
        const SizedBox(height: 16),
        _buildInstructionCategory('EXTENDED: DATA MOVEMENT', [
          const _InstructionInfo(
            mnemonic: 'LDB',
            hex: '0x0B',
            usage: 'LDB addr',
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
            description: 'Indexed load - Loads from the address held in B.',
            behavior:
                'B drives the bus into MAR (BO|MI), then RAM goes into A '
                '(RO|AI). Walks arrays and strings. One byte, no operand.',
            operandType: 'None ([B] is written in the source)',
            example: 'LDA [B] ; A = RAM[B]',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory('EXTENDED: ALU', [
          const _InstructionInfo(
            mnemonic: 'ADI',
            hex: '0x0C',
            usage: 'ADI #val',
            description: 'Add Immediate - A = A + val.',
            behavior: 'The value goes into B, then A + B into A. Sets C and Z.',
            operandType: imm,
            example: 'ADI 1 ; A = A + 1',
          ),
          const _InstructionInfo(
            mnemonic: 'SBI',
            hex: '0x0D',
            usage: 'SBI #val',
            description: 'Subtract Immediate - A = A - val.',
            behavior: 'Like ADI, subtracting. C is set on a borrow.',
            operandType: imm,
            example: 'SBI 1 ; A = A - 1',
          ),
          const _InstructionInfo(
            mnemonic: 'AND / OR / XOR',
            hex: '0x10-0x12',
            usage: 'AND addr',
            description: 'Bitwise logic - A = A op RAM[addr].',
            behavior: 'Bit by bit on A and B. Clears C, sets Z.',
            operandType: addr,
            example: 'AND mask ; keep the bits set in RAM[mask]',
          ),
          const _InstructionInfo(
            mnemonic: 'CMP',
            hex: '0x13',
            usage: 'CMP addr',
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
            description: 'Shift A left or right by one bit.',
            behavior:
                'The bit shifted out goes into C; a 0 comes in. SHL doubles, '
                'SHR halves.',
            operandType: 'None',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory('EXTENDED: JUMPS & STACK', [
          const _InstructionInfo(
            mnemonic: 'JNZ / JNC',
            hex: '0x0A / 0x09',
            usage: 'JNZ addr',
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
            description: 'Return from a subroutine.',
            behavior:
                'Pops the saved PC, then steps past the CALL\'s operand byte '
                '(CE), landing on the instruction after the CALL.',
            operandType: 'None',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory('EXTENDED: I/O PORTS', [
          const _InstructionInfo(
            mnemonic: 'OUT port',
            hex: '0x18',
            usage: 'OUT 2',
            description: 'Write A to the device on a port.',
            behavior:
                'The operand byte goes into the port register (RO|PI|CE), '
                'then A drives the bus and the device there reads it '
                '(AO|DI). Plain OUT is port 0, the display.',
            operandType: 'Port number (0-255), operand byte',
            example: 'OUT 2 ; A -> LCD data: show a character',
          ),
          const _InstructionInfo(
            mnemonic: 'IN port',
            hex: '0x19',
            usage: 'IN 5',
            description: 'Read the device on a port into A.',
            behavior:
                'Selects the port (RO|PI|CE), then the device drives the bus '
                'into A (DO|AI). Sets no flags: test the value with CMP. '
                'A port with nothing connected reads 0.',
            operandType: 'Port number (0-255), operand byte',
            example: 'IN 5 ; A = last key pressed, or 0',
          ),
        ]),
        const _PortMap(),
      ],
    );
  }

  Widget _buildOperandTypesSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSectionTitle('Operand types'),
        _OperandTypeCard(
          prefix: '#',
          name: 'Immediate Value',
          example: 'LDI #5',
          description:
              'A literal value (0-15) loaded directly into the register. '
              'Does NOT access memory - the value itself is used.',
        ),
        SizedBox(height: 6),
        _OperandTypeCard(
          prefix: '0x',
          name: 'Hexadecimal Address',
          example: 'LDA 0xE',
          description:
              'A memory address in hexadecimal format (0x0-0xF). '
              'Accesses the value stored at that RAM location.',
        ),
        SizedBox(height: 6),
        _OperandTypeCard(
          prefix: '',
          name: 'Decimal Address',
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
        _buildInstructionCategory('CONTROL FLOW', [
          const _InstructionInfo(
            mnemonic: 'NOP',
            hex: '0x0',
            usage: 'NOP',
            description: 'No Operation - Does nothing, uses one clock cycle.',
            behavior:
                'The program counter increments but no data is moved or modified.',
            operandType: 'None',
          ),
          const _InstructionInfo(
            mnemonic: 'HLT',
            hex: '0xF',
            usage: 'HLT',
            description: 'Halt - Stops program execution.',
            behavior:
                'The clock stops and the CPU enters a halted state. No further instructions execute.',
            operandType: 'None',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory('DATA MOVEMENT', [
          const _InstructionInfo(
            mnemonic: 'LDA',
            hex: '0x1',
            usage: 'LDA addr',
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
            description: 'Store to Address - Stores A register value into RAM.',
            behavior:
                'Writes the current value of register A to the specified memory address. '
                'A register value remains unchanged.',
            operandType: 'Address (0x0-0xF or 0-15)',
            example: 'STA 0xD ; Store A register value to RAM[13]',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory('ARITHMETIC', [
          const _InstructionInfo(
            mnemonic: 'ADD',
            hex: '0x2',
            usage: 'ADD addr',
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
            description: 'Subtract - Subtracts value from RAM from A register.',
            behavior:
                'Reads value from memory address, subtracts it from register A, stores result in A. '
                'Sets carry flag if underflow (result < 0). Sets zero flag if result = 0.',
            operandType: 'Address (0x0-0xF or 0-15)',
            example: 'SUB 14 ; A = A - RAM[14]',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory('JUMPS & BRANCHES', [
          const _InstructionInfo(
            mnemonic: 'JMP',
            hex: '0x6',
            usage: 'JMP addr',
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
            description: 'Jump if Zero - Jumps only if zero flag is set.',
            behavior:
                'If zero flag = 1 (last ALU result was 0), sets program counter to operand address. '
                'Otherwise, continues to next instruction. Used for conditional logic.',
            operandType: 'Address (0x0-0xF or 0-15)',
            example: 'JZ 10 ; Jump to address 10 if A = 0',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory('OUTPUT', [
          const _InstructionInfo(
            mnemonic: 'OUT',
            hex: '0xE',
            usage: 'OUT',
            description: 'Output - Displays value from A register.',
            behavior:
                'Sends the current value of register A to the output display '
                '(port 0). A register value remains unchanged.',
            operandType: 'None',
          ),
        ]),
      ],
    );
  }

  Widget _buildInstructionCategory(
    String name,
    List<_InstructionInfo> instructions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSectionTitle(name),
        for (final info in instructions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _InstructionCard(info: info),
          ),
      ],
    );
  }
}

class _InstructionInfo {
  final String mnemonic;
  final String hex;
  final String usage;
  final String description;
  final String behavior;
  final String operandType;
  final String? example;

  const _InstructionInfo({
    required this.mnemonic,
    required this.hex,
    required this.usage,
    required this.description,
    required this.behavior,
    required this.operandType,
    this.example,
  });
}

/// Mnemonic chip in the editor's instruction colour.
class _Mnemonic extends StatelessWidget {
  final String text;

  const _Mnemonic(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Glass.driveFill.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: Glass.mono,
          color: Glass.synOp,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Glass.raised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Glass.border),
      ),
      child: child,
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final _InstructionInfo info;

  const _InstructionCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Mnemonic(info.mnemonic),
              const SizedBox(width: 8),
              Text(
                info.hex,
                style: const TextStyle(
                  fontFamily: Glass.mono,
                  color: Glass.dim,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                info.usage,
                style: const TextStyle(
                  fontFamily: Glass.mono,
                  color: Glass.synArg,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            info.description,
            style: const TextStyle(
              color: Glass.text,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Operand  ',
                  style: TextStyle(
                    color: Glass.dim,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: info.operandType,
                  style: const TextStyle(color: Glass.synArg),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            info.behavior,
            style: const TextStyle(
              color: Glass.muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          if (info.example != null) ...[
            const SizedBox(height: 8),
            GlassCodeBlock(info.example!),
          ],
        ],
      ),
    );
  }
}

class _OperandTypeCard extends StatelessWidget {
  final String prefix;
  final String name;
  final String example;
  final String description;

  const _OperandTypeCard({
    required this.prefix,
    required this.name,
    required this.example,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Glass.ground,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Glass.borderSoft),
                ),
                child: Text(
                  prefix.isEmpty ? 'no prefix' : prefix,
                  style: TextStyle(
                    fontFamily: Glass.mono,
                    color: prefix.isEmpty ? Glass.dim : Glass.synArg,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontStyle: prefix.isEmpty ? FontStyle.italic : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  color: Glass.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                example,
                style: const TextStyle(
                  fontFamily: Glass.mono,
                  color: Glass.synArg,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: Glass.muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// What is connected to each I/O port.
class _PortMap extends StatelessWidget {
  const _PortMap();

  static const _ports = [
    ('0', 'Display', 'out', 'Output register: plain OUT, or OUT 0'),
    (
      '1',
      'Text LCD command',
      'out',
      '0x01 clear, 0x0C display on, 0x80+addr cursor; IN: cursor address',
    ),
    ('2', 'Text LCD data', 'out', 'A character at the cursor, which moves on'),
    (
      '3',
      'LED matrix row',
      'out',
      'Selects the row (0-7) the next data byte lights',
    ),
    (
      '4',
      'LED matrix data',
      'out',
      'Bit 7 = left LED; then the next row is selected',
    ),
    (
      '5',
      'Keypad',
      'in',
      "ASCII of the last key pressed ('0'-'9', 'A'-'D', '*', '#'), once; 0 if none",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Glass.raised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Glass.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Port map',
            style: TextStyle(
              color: Glass.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (final (port, device, direction, meaning) in _ports)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      port,
                      style: const TextStyle(
                        fontFamily: Glass.mono,
                        color: Glass.synArg,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(
                      device,
                      style: const TextStyle(color: Glass.text, fontSize: 12),
                    ),
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      direction,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: direction == 'in'
                            ? Glass.driveText
                            : Glass.readText,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      meaning,
                      style: const TextStyle(color: Glass.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          const Text(
            'The LCD starts with its display off, like the real HD44780: '
            'send 0x38 then 0x0C first. See the I/O devices built-in programs.',
            style: TextStyle(color: Glass.dim, fontSize: 11),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GlassSectionTitle('Labels, constants & data'),
        for (final (syntax, meaning) in _rules)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(
                    syntax,
                    style: const TextStyle(
                      fontFamily: Glass.mono,
                      color: Glass.synLabel,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    meaning,
                    style: const TextStyle(color: Glass.textSoft, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        const GlassCodeBlock(_example),
        const SizedBox(height: 6),
        const Text(
          'After Assemble & load, the gutter lists each line\'s address and '
          'first byte. Names are not case-sensitive.',
          style: TextStyle(color: Glass.dim, fontSize: 11),
        ),
      ],
    );
  }
}
