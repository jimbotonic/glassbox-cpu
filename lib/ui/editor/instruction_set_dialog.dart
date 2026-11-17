import 'package:flutter/material.dart';

import '../../core/cpu_mode.dart';
import '../../l10n/isa_strings.dart';
import '../board/glass_widgets.dart';
import '../theme/glass.dart';

class InstructionSetDialog extends StatelessWidget {
  /// Machine in use; Extended mode adds its section first.
  final CpuMode mode;

  const InstructionSetDialog({super.key, this.mode = CpuMode.classic});

  @override
  Widget build(BuildContext context) {
    final t = tIsa;
    return GlassDialogFrame(
      title: t.title,
      note: mode == CpuMode.extended ? t.noteExtended : t.noteClassic,
      width: 640,
      maxHeight: 720,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mode == CpuMode.extended) ...[
            _buildExtendedSection(t),
            const SizedBox(height: 20),
            GlassSectionTitle(t.classicInExtended),
            const SizedBox(height: 4),
          ],
          _buildOperandTypesSection(t),
          const SizedBox(height: 20),
          _buildInstructionsSection(t),
          const SizedBox(height: 20),
          const _SyntaxSection(),
        ],
      ),
    );
  }

  Widget _buildExtendedSection(IsaStrings t) {
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
          child: Text(
            t.extendedIntro,
            style: const TextStyle(
              color: Glass.textSoft,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInstructionCategory(t.catExtData, const [
          _InstructionInfo(
            IsaCard.ldb,
            mnemonic: 'LDB',
            hex: '0x0B',
            usage: 'LDB addr',
            exampleCode: 'LDB ptr',
          ),
          _InstructionInfo(
            IsaCard.ldaIndexed,
            mnemonic: 'LDA [B]',
            hex: '0x30',
            usage: 'LDA [B]',
            exampleCode: 'LDA [B]',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory(t.catExtAlu, const [
          _InstructionInfo(
            IsaCard.adi,
            mnemonic: 'ADI',
            hex: '0x0C',
            usage: 'ADI #val',
            exampleCode: 'ADI 1',
          ),
          _InstructionInfo(
            IsaCard.sbi,
            mnemonic: 'SBI',
            hex: '0x0D',
            usage: 'SBI #val',
            exampleCode: 'SBI 1',
          ),
          _InstructionInfo(
            IsaCard.logic,
            mnemonic: 'AND / OR / XOR',
            hex: '0x10-0x12',
            usage: 'AND addr',
            exampleCode: 'AND mask',
          ),
          _InstructionInfo(
            IsaCard.cmp,
            mnemonic: 'CMP',
            hex: '0x13',
            usage: 'CMP addr',
            exampleCode: 'CMP limit',
          ),
          _InstructionInfo(
            IsaCard.shift,
            mnemonic: 'SHL / SHR',
            hex: '0x14 / 0x15',
            usage: 'SHL',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory(t.catExtJumps, const [
          _InstructionInfo(
            IsaCard.jnzJnc,
            mnemonic: 'JNZ / JNC',
            hex: '0x0A / 0x09',
            usage: 'JNZ addr',
            exampleCode: 'JNZ loop',
          ),
          _InstructionInfo(
            IsaCard.pushPop,
            mnemonic: 'PUSH / POP',
            hex: '0x20 / 0x21',
            usage: 'PUSH',
          ),
          _InstructionInfo(
            IsaCard.call,
            mnemonic: 'CALL',
            hex: '0x22',
            usage: 'CALL addr',
            exampleCode: 'CALL multiply',
          ),
          _InstructionInfo(
            IsaCard.ret,
            mnemonic: 'RET',
            hex: '0x23',
            usage: 'RET',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory(t.catExtIo, const [
          _InstructionInfo(
            IsaCard.outPort,
            mnemonic: 'OUT port',
            hex: '0x18',
            usage: 'OUT 2',
            exampleCode: 'OUT 2',
          ),
          _InstructionInfo(
            IsaCard.inPort,
            mnemonic: 'IN port',
            hex: '0x19',
            usage: 'IN 5',
            exampleCode: 'IN 5',
          ),
        ]),
        const _PortMap(),
      ],
    );
  }

  Widget _buildOperandTypesSection(IsaStrings t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSectionTitle(t.operandTypes),
        _OperandTypeCard(
          prefix: '#',
          name: t.immediateName,
          example: 'LDI #5',
          description: t.immediateDesc,
        ),
        const SizedBox(height: 6),
        _OperandTypeCard(
          prefix: '0x',
          name: t.hexName,
          example: 'LDA 0xE',
          description: t.hexDesc,
        ),
        const SizedBox(height: 6),
        _OperandTypeCard(
          prefix: '',
          name: t.decimalName,
          example: 'LDA 14',
          description: t.decimalDesc,
        ),
      ],
    );
  }

  Widget _buildInstructionsSection(IsaStrings t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInstructionCategory(t.catControl, const [
          _InstructionInfo(
            IsaCard.nop,
            mnemonic: 'NOP',
            hex: '0x0',
            usage: 'NOP',
          ),
          _InstructionInfo(
            IsaCard.hlt,
            mnemonic: 'HLT',
            hex: '0xF',
            usage: 'HLT',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory(t.catData, const [
          _InstructionInfo(
            IsaCard.lda,
            mnemonic: 'LDA',
            hex: '0x1',
            usage: 'LDA addr',
            exampleCode: 'LDA 0xE',
          ),
          _InstructionInfo(
            IsaCard.ldi,
            mnemonic: 'LDI',
            hex: '0x5',
            usage: 'LDI #val',
            exampleCode: 'LDI #7',
          ),
          _InstructionInfo(
            IsaCard.sta,
            mnemonic: 'STA',
            hex: '0x4',
            usage: 'STA addr',
            exampleCode: 'STA 0xD',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory(t.catArith, const [
          _InstructionInfo(
            IsaCard.add,
            mnemonic: 'ADD',
            hex: '0x2',
            usage: 'ADD addr',
            exampleCode: 'ADD 0xF',
          ),
          _InstructionInfo(
            IsaCard.sub,
            mnemonic: 'SUB',
            hex: '0x3',
            usage: 'SUB addr',
            exampleCode: 'SUB 14',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory(t.catJumps, const [
          _InstructionInfo(
            IsaCard.jmp,
            mnemonic: 'JMP',
            hex: '0x6',
            usage: 'JMP addr',
            exampleCode: 'JMP 0',
          ),
          _InstructionInfo(
            IsaCard.jc,
            mnemonic: 'JC',
            hex: '0x7',
            usage: 'JC addr',
            exampleCode: 'JC 8',
          ),
          _InstructionInfo(
            IsaCard.jz,
            mnemonic: 'JZ',
            hex: '0x8',
            usage: 'JZ addr',
            exampleCode: 'JZ 10',
          ),
        ]),
        const SizedBox(height: 16),
        _buildInstructionCategory(t.catOutput, const [
          _InstructionInfo(
            IsaCard.out,
            mnemonic: 'OUT',
            hex: '0xE',
            usage: 'OUT',
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

/// One card's code-side facts; its text comes from [IsaStrings.entry].
class _InstructionInfo {
  final IsaCard card;
  final String mnemonic;
  final String hex;
  final String usage;

  /// Code of the example, if any; its `; comment` comes from the entry.
  final String? exampleCode;

  const _InstructionInfo(
    this.card, {
    required this.mnemonic,
    required this.hex,
    required this.usage,
    this.exampleCode,
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
    final t = tIsa;
    final entry = t.entry(info.card);
    final code = info.exampleCode;
    final note = entry.exampleNote;
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
            entry.description,
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
                TextSpan(
                  text: t.operandLabel,
                  style: const TextStyle(
                    color: Glass.dim,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: entry.operand,
                  style: const TextStyle(color: Glass.synArg),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            entry.behavior,
            style: const TextStyle(
              color: Glass.muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          if (code != null) ...[
            const SizedBox(height: 8),
            GlassCodeBlock(note == null ? code : '$code ; $note'),
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
                  prefix.isEmpty ? tIsa.noPrefix : prefix,
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

  /// Port number and whether it is an input; the text is in [IsaStrings].
  static const _ports = [
    (0, false),
    (1, false),
    (2, false),
    (3, false),
    (4, false),
    (5, true),
  ];

  @override
  Widget build(BuildContext context) {
    final t = tIsa;
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
          Text(
            t.portMap,
            style: const TextStyle(
              color: Glass.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (final (port, isInput) in _ports)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '$port',
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
                      t.port(port).$1,
                      style: const TextStyle(color: Glass.text, fontSize: 12),
                    ),
                  ),
                  SizedBox(
                    width: 46,
                    child: Text(
                      isInput ? t.dirIn : t.dirOut,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isInput ? Glass.driveText : Glass.readText,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t.port(port).$2,
                      style: const TextStyle(color: Glass.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            t.lcdNote,
            style: const TextStyle(color: Glass.dim, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Labels, `.equ` constants and `.db` data, with a worked example.
class _SyntaxSection extends StatelessWidget {
  const _SyntaxSection();

  /// Syntax of each rule; the meanings are in [IsaStrings].
  static const _syntax = [
    'label:',
    '.equ NAME value',
    '.db 1, 0x2A, \'A\', "HI"',
    '0x1F  0b101  \'A\'',
  ];

  @override
  Widget build(BuildContext context) {
    final t = tIsa;
    final meanings = [t.ruleLabel, t.ruleEqu, t.ruleDb, t.ruleLiterals];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSectionTitle(t.syntaxTitle),
        for (var i = 0; i < _syntax.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(
                    _syntax[i],
                    style: const TextStyle(
                      fontFamily: Glass.mono,
                      color: Glass.synLabel,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    meanings[i],
                    style: const TextStyle(color: Glass.textSoft, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        GlassCodeBlock(t.syntaxExample),
        const SizedBox(height: 6),
        Text(
          t.syntaxNote,
          style: const TextStyle(color: Glass.dim, fontSize: 11),
        ),
      ],
    );
  }
}
