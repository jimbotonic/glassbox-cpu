import '../core/opcode.dart';
import 'l10n.dart';

/// One card of the instruction set reference, and the opcodes it documents.
/// Together the cards cover every [Opcode].
enum IsaCard {
  // Extended only.
  ldb([Opcode.ldb]),
  ldaIndexed([Opcode.ldaIndexed]),
  adi([Opcode.adi]),
  sbi([Opcode.sbi]),
  logic([Opcode.and, Opcode.or, Opcode.xor]),
  cmp([Opcode.cmp]),
  shift([Opcode.shl, Opcode.shr]),
  jnzJnc([Opcode.jnz, Opcode.jnc]),
  pushPop([Opcode.push, Opcode.pop]),
  call([Opcode.call]),
  ret([Opcode.ret]),
  outPort([Opcode.outPort]),
  inPort([Opcode.inPort]),
  // Classic.
  nop([Opcode.nop]),
  hlt([Opcode.hlt]),
  lda([Opcode.lda]),
  ldi([Opcode.ldi]),
  sta([Opcode.sta]),
  add([Opcode.add]),
  sub([Opcode.sub]),
  jmp([Opcode.jmp]),
  jc([Opcode.jc]),
  jz([Opcode.jz]),
  out([Opcode.out]);

  final List<Opcode> opcodes;
  const IsaCard(this.opcodes);
}

/// Text of one instruction card. [exampleNote] is the `; comment` after the
/// example code, or null when the example has none.
class IsaEntry {
  final String description;
  final String operand;
  final String behavior;
  final String? exampleNote;

  const IsaEntry(
    this.description,
    this.operand,
    this.behavior, [
    this.exampleNote,
  ]);
}

/// Text of the instruction set reference.
abstract class IsaStrings {
  String get title; // 'INSTRUCTION SET'
  String get noteExtended;
  String get noteClassic;
  String get classicInExtended;
  String get extendedIntro;

  String get catExtData;
  String get catExtAlu;
  String get catExtJumps;
  String get catExtIo;
  String get catControl;
  String get catData;
  String get catArith;
  String get catJumps;
  String get catOutput;

  String get operandTypes;
  String get immediateName;
  String get immediateDesc;
  String get hexName;
  String get hexDesc;
  String get decimalName;
  String get decimalDesc;
  String get noPrefix;

  /// Label before the operand type on a card, with its trailing spaces.
  String get operandLabel; // 'Operand  '

  /// The text of [card].
  IsaEntry entry(IsaCard card);

  String get portMap;

  /// Device name and meaning of I/O port [port], 0-5.
  (String, String) port(int port);
  String get dirIn;
  String get dirOut;
  String get lcdNote;

  String get syntaxTitle;
  String get ruleLabel;
  String get ruleEqu;
  String get ruleDb;
  String get ruleLiterals;

  /// The worked example: the same code in every language, comments
  /// translated.
  String get syntaxExample;
  String get syntaxNote;

  /// RAM panel line for the operand byte after an Extended opcode.
  String get operandRow; // '  ↳ operand'
}

/// The current language's instruction set text.
IsaStrings get tIsa => L10n.pick(const _En(), const _Fr(), const _De());

String _example(
  String constant,
  String label,
  String names,
  String forward,
  String data,
) =>
    '.equ STEP 1       ; $constant\n'
    'loop: LDA n       ; $label\n'
    '      OUT\n'
    '      SUB step    ; $names\n'
    '      STA n\n'
    '      JZ  done    ; $forward\n'
    '      JMP loop\n'
    'done: HLT\n'
    'n:    .db 5       ; $data\n'
    'step: .db STEP';

class _En implements IsaStrings {
  const _En();

  @override
  String get title => 'INSTRUCTION SET';
  @override
  String get noteExtended =>
      'Every instruction of the Extended CPU, then the Classic ones it keeps.';
  @override
  String get noteClassic =>
      'Every instruction of the Classic CPU, its operand and an example.';
  @override
  String get classicInExtended =>
      'Classic instructions, also in Extended with 8-bit operands '
      '(addresses 0-255, values -128..255)';
  @override
  String get extendedIntro =>
      'EXTENDED CPU: 256 bytes of RAM. An instruction is an opcode '
      'byte, followed by an operand byte when it takes an address or '
      'a value; the CPU reads that byte at the program counter '
      '(CO|MI, then RO|..|CE). Names ending in I take a value, the '
      'others an address. The ALU always works on A and B, so ADD, '
      'SUB, AND, OR, XOR, CMP, ADI and SBI overwrite B. The stack '
      'grows down from 0xFF; keep code and data below it.';

  @override
  String get catExtData => 'EXTENDED: DATA MOVEMENT';
  @override
  String get catExtAlu => 'EXTENDED: ALU';
  @override
  String get catExtJumps => 'EXTENDED: JUMPS & STACK';
  @override
  String get catExtIo => 'EXTENDED: I/O PORTS';
  @override
  String get catControl => 'CONTROL FLOW';
  @override
  String get catData => 'DATA MOVEMENT';
  @override
  String get catArith => 'ARITHMETIC';
  @override
  String get catJumps => 'JUMPS & BRANCHES';
  @override
  String get catOutput => 'OUTPUT';

  @override
  String get operandTypes => 'Operand types';
  @override
  String get immediateName => 'Immediate Value';
  @override
  String get immediateDesc =>
      'A literal value (0-15) loaded directly into the register. '
      'Does NOT access memory - the value itself is used.';
  @override
  String get hexName => 'Hexadecimal Address';
  @override
  String get hexDesc =>
      'A memory address in hexadecimal format (0x0-0xF). '
      'Accesses the value stored at that RAM location.';
  @override
  String get decimalName => 'Decimal Address';
  @override
  String get decimalDesc =>
      'A memory address in decimal format (0-15). '
      'Accesses the value stored at that RAM location. Same as hex, just '
      'different notation.';
  @override
  String get noPrefix => 'no prefix';
  @override
  String get operandLabel => 'Operand  ';

  static const _none = 'None';
  static const _extAddr = 'Address (0-255), operand byte';
  static const _extImm = 'Value (-128..255), operand byte';
  static const _port = 'Port number (0-255), operand byte';
  static const _addr = 'Address (0x0-0xF or 0-15)';

  @override
  IsaEntry entry(IsaCard card) => switch (card) {
    IsaCard.ldb => const IsaEntry(
      'Load B - Loads value from RAM into B register.',
      _extAddr,
      'Reads RAM[addr] into B. Use it to set the index for LDA [B].',
      'B = RAM[ptr]',
    ),
    IsaCard.ldaIndexed => const IsaEntry(
      'Indexed load - Loads from the address held in B.',
      'None ([B] is written in the source)',
      'B drives the bus into MAR (BO|MI), then RAM goes into A '
          '(RO|AI). Walks arrays and strings. One byte, no operand.',
      'A = RAM[B]',
    ),
    IsaCard.adi => const IsaEntry(
      'Add Immediate - A = A + val.',
      _extImm,
      'The value goes into B, then A + B into A. Sets C and Z.',
      'A = A + 1',
    ),
    IsaCard.sbi => const IsaEntry(
      'Subtract Immediate - A = A - val.',
      _extImm,
      'Like ADI, subtracting. C is set on a borrow.',
      'A = A - 1',
    ),
    IsaCard.logic => const IsaEntry(
      'Bitwise logic - A = A op RAM[addr].',
      _extAddr,
      'Bit by bit on A and B. Clears C, sets Z.',
      'keep the bits set in RAM[mask]',
    ),
    IsaCard.cmp => const IsaEntry(
      'Compare - Computes A - RAM[addr] for the flags only.',
      _extAddr,
      'A is unchanged. Z = 1 when equal; C = 1 when A is smaller.',
      'then JZ / JC / JNZ / JNC',
    ),
    IsaCard.shift => const IsaEntry(
      'Shift A left or right by one bit.',
      _none,
      'The bit shifted out goes into C; a 0 comes in. SHL doubles, '
          'SHR halves.',
    ),
    IsaCard.jnzJnc => const IsaEntry(
      'Jump if Not Zero / Not Carry.',
      _extAddr,
      'Jumps when the flag is 0. Otherwise one step (CE) skips the '
          'operand byte.',
    ),
    IsaCard.pushPop => const IsaEntry(
      'Save A on the stack / restore it.',
      _none,
      'PUSH writes A at RAM[SP] then SP = SP - 1. POP does SP = SP '
          '+ 1 then A = RAM[SP]. Last in, first out.',
    ),
    IsaCard.call => const IsaEntry(
      'Call a subroutine.',
      _extAddr,
      'Pushes PC (the address of its own operand byte), then jumps '
          'to addr.',
    ),
    IsaCard.ret => const IsaEntry(
      'Return from a subroutine.',
      _none,
      'Pops the saved PC, then steps past the CALL\'s operand byte '
          '(CE), landing on the instruction after the CALL.',
    ),
    IsaCard.outPort => const IsaEntry(
      'Write A to the device on a port.',
      _port,
      'The operand byte goes into the port register (RO|PI|CE), '
          'then A drives the bus and the device there reads it '
          '(AO|DI). Plain OUT is port 0, the display.',
      'A -> LCD data: show a character',
    ),
    IsaCard.inPort => const IsaEntry(
      'Read the device on a port into A.',
      _port,
      'Selects the port (RO|PI|CE), then the device drives the bus '
          'into A (DO|AI). Sets no flags: test the value with CMP. '
          'A port with nothing connected reads 0.',
      'A = last key pressed, or 0',
    ),
    IsaCard.nop => const IsaEntry(
      'No Operation - Does nothing, uses one clock cycle.',
      _none,
      'The program counter increments but no data is moved or modified.',
    ),
    IsaCard.hlt => const IsaEntry(
      'Halt - Stops program execution.',
      _none,
      'The clock stops and the CPU enters a halted state. No further '
          'instructions execute.',
    ),
    IsaCard.lda => const IsaEntry(
      'Load from Address - Loads value from RAM into A register.',
      _addr,
      'Reads the value at the specified memory address and stores it in '
          'register A. Previous A register value is overwritten.',
      'Load value from RAM[14] into A',
    ),
    IsaCard.ldi => const IsaEntry(
      'Load Immediate - Loads a literal value into A register.',
      'Immediate value (#0-#15)',
      'Stores the immediate value directly into register A. '
          'Does NOT access memory - the operand IS the value.',
      'Load the number 7 into A',
    ),
    IsaCard.sta => const IsaEntry(
      'Store to Address - Stores A register value into RAM.',
      _addr,
      'Writes the current value of register A to the specified memory '
          'address. A register value remains unchanged.',
      'Store A register value to RAM[13]',
    ),
    IsaCard.add => const IsaEntry(
      'Add - Adds value from RAM to A register.',
      _addr,
      'Reads value from memory address, adds it to register A, stores '
          'result in A. Sets carry flag if result > 255. Sets zero flag if '
          'result = 0.',
      'A = A + RAM[15]',
    ),
    IsaCard.sub => const IsaEntry(
      'Subtract - Subtracts value from RAM from A register.',
      _addr,
      'Reads value from memory address, subtracts it from register A, '
          'stores result in A. Sets carry flag on a borrow (value larger '
          'than A, so the result wraps below 0). '
          'Sets zero flag if result = 0.',
      'A = A - RAM[14]',
    ),
    IsaCard.jmp => const IsaEntry(
      'Jump - Unconditionally jumps to specified address.',
      _addr,
      'Sets the program counter to the operand address. Execution '
          'continues from that address. Used for loops and function calls.',
      'Jump back to start of program',
    ),
    IsaCard.jc => const IsaEntry(
      'Jump if Carry - Jumps only if carry flag is set.',
      _addr,
      'If carry flag = 1, sets program counter to operand address. '
          'Otherwise, continues to next instruction. Used for overflow '
          'detection.',
      'Jump to address 8 if overflow occurred',
    ),
    IsaCard.jz => const IsaEntry(
      'Jump if Zero - Jumps only if zero flag is set.',
      _addr,
      'If zero flag = 1 (last ALU result was 0), sets program counter to '
          'operand address. Otherwise, continues to next instruction. Used '
          'for conditional logic.',
      'Jump to address 10 if A = 0',
    ),
    IsaCard.out => const IsaEntry(
      'Output - Displays value from A register.',
      _none,
      'Sends the current value of register A to the output display '
          '(port 0). A register value remains unchanged.',
    ),
  };

  @override
  String get portMap => 'Port map';
  @override
  (String, String) port(int port) => switch (port) {
    0 => ('Display', 'Output register: plain OUT, or OUT 0'),
    1 => (
      'Text LCD command',
      '0x01 clear, 0x0C display on, 0x80+addr cursor; IN: cursor address',
    ),
    2 => ('Text LCD data', 'A character at the cursor, which moves on'),
    3 => ('LED matrix row', 'Selects the row (0-7) the next data byte lights'),
    4 => ('LED matrix data', 'Bit 7 = left LED; then the next row is selected'),
    _ => (
      'Keypad',
      "ASCII of the last key pressed ('0'-'9', 'A'-'D', '*', '#'), once; "
          '0 if none',
    ),
  };
  @override
  String get dirIn => 'in';
  @override
  String get dirOut => 'out';
  @override
  String get lcdNote =>
      'The LCD starts with its display off, like the real HD44780: '
      'send 0x38 then 0x0C first. See the I/O devices built-in programs.';

  @override
  String get syntaxTitle => 'Labels, constants & data';
  @override
  String get ruleLabel =>
      'Names the address of the next byte. Use it as an operand.';
  @override
  String get ruleEqu => 'Defines a constant. Takes no space in RAM.';
  @override
  String get ruleDb =>
      'Places bytes (0-255) in RAM: numbers, characters, strings, labels.';
  @override
  String get ruleLiterals => 'Hex, binary and character literals.';
  @override
  String get syntaxExample => _example(
    'constant: a name for a number',
    'label: a name for an address',
    'names work wherever a number does',
    'jump forward to a label',
    'data: one byte per value',
  );
  @override
  String get syntaxNote =>
      'After Assemble & load, the gutter lists each line\'s address and '
      'first byte. Names are not case-sensitive.';

  @override
  String get operandRow => '  ↳ operand';
}

class _Fr implements IsaStrings {
  const _Fr();

  @override
  String get title => "JEU D'INSTRUCTIONS";
  @override
  String get noteExtended =>
      "Toutes les instructions du CPU étendu, puis les instructions "
      "classiques qu'il conserve.";
  @override
  String get noteClassic =>
      'Chaque instruction du CPU classique, son opérande et un exemple.';
  @override
  String get classicInExtended =>
      'Instructions classiques, aussi en mode étendu avec des opérandes '
      '8 bits (adresses 0-255, valeurs -128..255)';
  @override
  String get extendedIntro =>
      "CPU ÉTENDU : 256 octets de RAM. Une instruction est un octet "
      "d'opcode, suivi d'un octet d'opérande quand elle prend une adresse "
      "ou une valeur ; le CPU lit cet octet à l'adresse du compteur de "
      "programme (CO|MI, puis RO|..|CE). Les noms finissant par I prennent "
      "une valeur, les autres une adresse. L'UAL travaille toujours sur A "
      "et B, donc ADD, SUB, AND, OR, XOR, CMP, ADI et SBI écrasent B. La "
      "pile croît vers le bas à partir de 0xFF ; garder le code et les "
      "données en dessous.";

  @override
  String get catExtData => 'ÉTENDU : TRANSFERT DE DONNÉES';
  @override
  String get catExtAlu => 'ÉTENDU : UAL';
  @override
  String get catExtJumps => 'ÉTENDU : SAUTS ET PILE';
  @override
  String get catExtIo => "ÉTENDU : PORTS D'E/S";
  @override
  String get catControl => 'FLUX DE CONTRÔLE';
  @override
  String get catData => 'TRANSFERT DE DONNÉES';
  @override
  String get catArith => 'ARITHMÉTIQUE';
  @override
  String get catJumps => 'SAUTS ET BRANCHEMENTS';
  @override
  String get catOutput => 'SORTIE';

  @override
  String get operandTypes => "Types d'opérande";
  @override
  String get immediateName => 'Valeur immédiate';
  @override
  String get immediateDesc =>
      'Une valeur littérale (0-15) chargée directement dans le registre. '
      "N'accède PAS à la mémoire - la valeur elle-même est utilisée.";
  @override
  String get hexName => 'Adresse hexadécimale';
  @override
  String get hexDesc =>
      'Une adresse mémoire au format hexadécimal (0x0-0xF). '
      'Accède à la valeur stockée à cet emplacement de la RAM.';
  @override
  String get decimalName => 'Adresse décimale';
  @override
  String get decimalDesc =>
      'Une adresse mémoire au format décimal (0-15). '
      'Accède à la valeur stockée à cet emplacement de la RAM. Comme en '
      'hexadécimal, seule la notation change.';
  @override
  String get noPrefix => 'sans préfixe';
  @override
  String get operandLabel => 'Opérande  ';

  static const _none = 'Aucun';
  static const _extAddr = "Adresse (0-255), octet d'opérande";
  static const _extImm = "Valeur (-128..255), octet d'opérande";
  static const _port = "Numéro de port (0-255), octet d'opérande";
  static const _addr = 'Adresse (0x0-0xF ou 0-15)';

  @override
  IsaEntry entry(IsaCard card) => switch (card) {
    IsaCard.ldb => const IsaEntry(
      'Charger B - Charge une valeur de la RAM dans le registre B.',
      _extAddr,
      "Lit RAM[addr] dans B. Sert à fixer l'index pour LDA [B].",
      'B = RAM[ptr]',
    ),
    IsaCard.ldaIndexed => const IsaEntry(
      "Chargement indexé - Charge depuis l'adresse contenue dans B.",
      'Aucun ([B] est écrit dans le code source)',
      'B pilote le bus vers le MAR (BO|MI), puis la RAM va dans A '
          "(RO|AI). Parcourt tableaux et chaînes. Un octet, pas d'opérande.",
      'A = RAM[B]',
    ),
    IsaCard.adi => const IsaEntry(
      'Addition immédiate - A = A + val.',
      _extImm,
      'La valeur va dans B, puis A + B dans A. Positionne C et Z.',
      'A = A + 1',
    ),
    IsaCard.sbi => const IsaEntry(
      'Soustraction immédiate - A = A - val.',
      _extImm,
      "Comme ADI, en soustrayant. C est mis à 1 en cas d'emprunt.",
      'A = A - 1',
    ),
    IsaCard.logic => const IsaEntry(
      'Logique bit à bit - A = A op RAM[addr].',
      _extAddr,
      'Bit par bit sur A et B. Met C à 0, positionne Z.',
      'garder les bits à 1 dans RAM[mask]',
    ),
    IsaCard.cmp => const IsaEntry(
      'Comparer - Calcule A - RAM[addr] pour les indicateurs seulement.',
      _extAddr,
      'A reste inchangé. Z = 1 si égalité ; C = 1 si A est plus petit.',
      'puis JZ / JC / JNZ / JNC',
    ),
    IsaCard.shift => const IsaEntry(
      "Décale A d'un bit à gauche ou à droite.",
      _none,
      'Le bit sorti va dans C ; un 0 entre. SHL double, SHR divise '
          'par deux.',
    ),
    IsaCard.jnzJnc => const IsaEntry(
      'Saut si non zéro / sans retenue.',
      _extAddr,
      "Saute quand l'indicateur vaut 0. Sinon, une étape (CE) saute "
          "l'octet d'opérande.",
    ),
    IsaCard.pushPop => const IsaEntry(
      'Sauver A sur la pile / le restaurer.',
      _none,
      'PUSH écrit A en RAM[SP] puis SP = SP - 1. POP fait SP = SP '
          '+ 1 puis A = RAM[SP]. Dernier entré, premier sorti.',
    ),
    IsaCard.call => const IsaEntry(
      'Appeler un sous-programme.',
      _extAddr,
      "Empile PC (l'adresse de son propre octet d'opérande), puis saute "
          'à addr.',
    ),
    IsaCard.ret => const IsaEntry(
      "Retour d'un sous-programme.",
      _none,
      "Dépile le PC sauvé, puis passe l'octet d'opérande du CALL (CE) "
          "pour arriver sur l'instruction qui suit le CALL.",
    ),
    IsaCard.outPort => const IsaEntry(
      "Écrire A vers le périphérique d'un port.",
      _port,
      "L'octet d'opérande va dans le registre de port (RO|PI|CE), "
          'puis A pilote le bus et le périphérique de ce port le lit '
          "(AO|DI). OUT seul est le port 0, l'afficheur.",
      'A -> données LCD : afficher un caractère',
    ),
    IsaCard.inPort => const IsaEntry(
      "Lire le périphérique d'un port dans A.",
      _port,
      'Sélectionne le port (RO|PI|CE), puis le périphérique pilote le bus '
          'vers A (DO|AI). Ne modifie aucun indicateur : tester la '
          "valeur avec CMP. Un port où rien n'est branché donne 0.",
      'A = dernière touche pressée, ou 0',
    ),
    IsaCard.nop => const IsaEntry(
      "Aucune opération - Ne fait rien, prend un cycle d'horloge.",
      _none,
      "Le compteur de programme s'incrémente mais aucune donnée n'est "
          'déplacée ni modifiée.',
    ),
    IsaCard.hlt => const IsaEntry(
      "Arrêt - Arrête l'exécution du programme.",
      _none,
      "L'horloge s'arrête et le CPU passe à l'état arrêté. Aucune autre "
          "instruction ne s'exécute.",
    ),
    IsaCard.lda => const IsaEntry(
      'Charger depuis une adresse - Charge une valeur de la RAM dans le '
          'registre A.',
      _addr,
      "Lit la valeur à l'adresse mémoire indiquée et la place dans le "
          "registre A. L'ancienne valeur du registre A est écrasée.",
      'Charge la valeur de RAM[14] dans A',
    ),
    IsaCard.ldi => const IsaEntry(
      'Chargement immédiat - Charge une valeur littérale dans le '
          'registre A.',
      'Valeur immédiate (#0-#15)',
      'Place la valeur immédiate directement dans le registre A. '
          "N'accède PAS à la mémoire - l'opérande EST la valeur.",
      'Charge le nombre 7 dans A',
    ),
    IsaCard.sta => const IsaEntry(
      'Stocker à une adresse - Stocke la valeur du registre A en RAM.',
      _addr,
      'Écrit la valeur actuelle du registre A à l\'adresse mémoire '
          'indiquée. La valeur du registre A reste inchangée.',
      'Stocke la valeur du registre A en RAM[13]',
    ),
    IsaCard.add => const IsaEntry(
      'Additionner - Ajoute une valeur de la RAM au registre A.',
      _addr,
      "Lit la valeur à l'adresse mémoire, l'ajoute au registre A, place "
          'le résultat dans A. Met la retenue à 1 si le résultat > 255. '
          "Met l'indicateur zéro à 1 si le résultat = 0.",
      'A = A + RAM[15]',
    ),
    IsaCard.sub => const IsaEntry(
      'Soustraire - Soustrait une valeur de la RAM du registre A.',
      _addr,
      "Lit la valeur à l'adresse mémoire, la soustrait du registre A, "
          'place le résultat dans A. Met la retenue à 1 en cas d’emprunt '
          '(valeur plus grande que A, le résultat repasse sous 0). '
          "Met l'indicateur zéro à 1 "
          'si le résultat = 0.',
      'A = A - RAM[14]',
    ),
    IsaCard.jmp => const IsaEntry(
      "Sauter - Saute sans condition à l'adresse indiquée.",
      _addr,
      "Met l'adresse de l'opérande dans le compteur de programme. "
          "L'exécution continue à cette adresse. Sert aux boucles et aux "
          'appels de fonction.',
      'Retour au début du programme',
    ),
    IsaCard.jc => const IsaEntry(
      'Saut si retenue - Saute seulement si la retenue est à 1.',
      _addr,
      "Si retenue = 1, met l'adresse de l'opérande dans le compteur de "
          "programme. Sinon, passe à l'instruction suivante. Sert à "
          'détecter un dépassement.',
      "Saute à l'adresse 8 en cas de dépassement",
    ),
    IsaCard.jz => const IsaEntry(
      "Saut si zéro - Saute seulement si l'indicateur zéro est à 1.",
      _addr,
      "Si l'indicateur zéro = 1 (le dernier résultat de l'UAL valait 0), "
          "met l'adresse de l'opérande dans le compteur de programme. "
          "Sinon, passe à l'instruction suivante. Sert aux conditions.",
      "Saute à l'adresse 10 si A = 0",
    ),
    IsaCard.out => const IsaEntry(
      'Sortie - Affiche la valeur du registre A.',
      _none,
      'Envoie la valeur actuelle du registre A à l\'afficheur de sortie '
          '(port 0). La valeur du registre A reste inchangée.',
    ),
  };

  @override
  String get portMap => 'Carte des ports';
  @override
  (String, String) port(int port) => switch (port) {
    0 => ('Afficheur', 'Registre de sortie : OUT seul, ou OUT 0'),
    1 => (
      'Commande LCD texte',
      '0x01 effacer, 0x0C affichage allumé, 0x80+addr curseur ; '
          'IN : adresse du curseur',
    ),
    2 => ('Données LCD texte', 'Un caractère au curseur, qui avance'),
    3 => (
      'Ligne matrice LED',
      "Choisit la ligne (0-7) qu'allume le prochain octet de données",
    ),
    4 => (
      'Données matrice LED',
      'Bit 7 = LED de gauche ; puis la ligne suivante est choisie',
    ),
    _ => (
      'Clavier',
      "ASCII de la dernière touche pressée ('0'-'9', 'A'-'D', '*', '#'), "
          'une seule fois ; 0 sinon',
    ),
  };
  @override
  String get dirIn => 'entrée';
  @override
  String get dirOut => 'sortie';
  @override
  String get lcdNote =>
      "L'écran LCD démarre affichage éteint, comme le vrai HD44780 : "
      "envoyer d'abord 0x38 puis 0x0C. Voir les programmes intégrés des "
      "périphériques d'E/S.";

  @override
  String get syntaxTitle => 'Étiquettes, constantes et données';
  @override
  String get ruleLabel =>
      "Nomme l'adresse de l'octet suivant. S'utilise comme opérande.";
  @override
  String get ruleEqu => "Définit une constante. N'occupe aucune place en RAM.";
  @override
  String get ruleDb =>
      'Place des octets (0-255) en RAM : nombres, caractères, chaînes, '
      'étiquettes.';
  @override
  String get ruleLiterals => 'Littéraux hexadécimaux, binaires et caractères.';
  @override
  String get syntaxExample => _example(
    'constante : un nom pour un nombre',
    'étiquette : un nom pour une adresse',
    'un nom vaut partout où va un nombre',
    'saut en avant vers une étiquette',
    'données : un octet par valeur',
  );
  @override
  String get syntaxNote =>
      'Après « Assembler et charger », la marge indique l\'adresse '
      'et le premier octet de chaque ligne. Les noms ignorent la casse.';

  @override
  String get operandRow => '  ↳ opérande';
}

class _De implements IsaStrings {
  const _De();

  @override
  String get title => 'BEFEHLSSATZ';
  @override
  String get noteExtended =>
      'Alle Befehle der erweiterten CPU, danach die klassischen, die sie '
      'behält.';
  @override
  String get noteClassic =>
      'Jeder Befehl der klassischen CPU, sein Operand und ein Beispiel.';
  @override
  String get classicInExtended =>
      'Klassische Befehle, auch im erweiterten Modus mit 8-Bit-Operanden '
      '(Adressen 0-255, Werte -128..255)';
  @override
  String get extendedIntro =>
      'ERWEITERTE CPU: 256 Byte RAM. Ein Befehl ist ein Opcode-Byte, '
      'gefolgt von einem Operanden-Byte, wenn er eine Adresse oder einen '
      'Wert nimmt; die CPU liest dieses Byte an der Adresse im '
      'Programmzähler (CO|MI, dann RO|..|CE). Namen auf I nehmen einen '
      'Wert, die anderen eine Adresse. Die ALU arbeitet immer mit A und B, '
      'daher überschreiben ADD, SUB, AND, OR, XOR, CMP, ADI und SBI das '
      'Register B. Der Stapel wächst ab 0xFF nach unten; Code und Daten '
      'darunter halten.';

  @override
  String get catExtData => 'ERWEITERT: DATENTRANSFER';
  @override
  String get catExtAlu => 'ERWEITERT: ALU';
  @override
  String get catExtJumps => 'ERWEITERT: SPRÜNGE & STAPEL';
  @override
  String get catExtIo => 'ERWEITERT: E/A-PORTS';
  @override
  String get catControl => 'PROGRAMMABLAUF';
  @override
  String get catData => 'DATENTRANSFER';
  @override
  String get catArith => 'ARITHMETIK';
  @override
  String get catJumps => 'SPRÜNGE & VERZWEIGUNGEN';
  @override
  String get catOutput => 'AUSGABE';

  @override
  String get operandTypes => 'Operandenarten';
  @override
  String get immediateName => 'Direktwert';
  @override
  String get immediateDesc =>
      'Ein literaler Wert (0-15), direkt ins Register geladen. '
      'Greift NICHT auf den Speicher zu - der Wert selbst wird verwendet.';
  @override
  String get hexName => 'Hexadezimale Adresse';
  @override
  String get hexDesc =>
      'Eine Speicheradresse im Hexadezimalformat (0x0-0xF). '
      'Greift auf den Wert an dieser RAM-Stelle zu.';
  @override
  String get decimalName => 'Dezimale Adresse';
  @override
  String get decimalDesc =>
      'Eine Speicheradresse im Dezimalformat (0-15). '
      'Greift auf den Wert an dieser RAM-Stelle zu. Wie hexadezimal, nur '
      'eine andere Schreibweise.';
  @override
  String get noPrefix => 'ohne Präfix';
  @override
  String get operandLabel => 'Operand  ';

  static const _none = 'Keiner';
  static const _extAddr = 'Adresse (0-255), Operanden-Byte';
  static const _extImm = 'Wert (-128..255), Operanden-Byte';
  static const _port = 'Portnummer (0-255), Operanden-Byte';
  static const _addr = 'Adresse (0x0-0xF oder 0-15)';

  @override
  IsaEntry entry(IsaCard card) => switch (card) {
    IsaCard.ldb => const IsaEntry(
      'B laden - Lädt einen Wert aus dem RAM in Register B.',
      _extAddr,
      'Liest RAM[addr] nach B. Setzt so den Index für LDA [B].',
      'B = RAM[ptr]',
    ),
    IsaCard.ldaIndexed => const IsaEntry(
      'Indiziertes Laden - Lädt von der Adresse in B.',
      'Keiner ([B] steht im Quelltext)',
      'B treibt den Bus ins MAR (BO|MI), dann geht der RAM-Wert nach A '
          '(RO|AI). Durchläuft Arrays und Zeichenketten. Ein Byte, kein '
          'Operand.',
      'A = RAM[B]',
    ),
    IsaCard.adi => const IsaEntry(
      'Direkt addieren - A = A + val.',
      _extImm,
      'Der Wert geht nach B, dann A + B nach A. Setzt C und Z.',
      'A = A + 1',
    ),
    IsaCard.sbi => const IsaEntry(
      'Direkt subtrahieren - A = A - val.',
      _extImm,
      'Wie ADI, nur subtrahierend. C wird bei einem Borgen gesetzt.',
      'A = A - 1',
    ),
    IsaCard.logic => const IsaEntry(
      'Bitweise Logik - A = A op RAM[addr].',
      _extAddr,
      'Bit für Bit auf A und B. Löscht C, setzt Z.',
      'die in RAM[mask] gesetzten Bits behalten',
    ),
    IsaCard.cmp => const IsaEntry(
      'Vergleichen - Berechnet A - RAM[addr] nur für die Flags.',
      _extAddr,
      'A bleibt unverändert. Z = 1 bei Gleichheit; C = 1, wenn A kleiner '
          'ist.',
      'danach JZ / JC / JNZ / JNC',
    ),
    IsaCard.shift => const IsaEntry(
      'Schiebt A um ein Bit nach links oder rechts.',
      _none,
      'Das hinausgeschobene Bit geht nach C; eine 0 rückt nach. SHL '
          'verdoppelt, SHR halbiert.',
    ),
    IsaCard.jnzJnc => const IsaEntry(
      'Springen, wenn nicht Null / kein Übertrag.',
      _extAddr,
      'Springt, wenn das Flag 0 ist. Sonst überspringt ein Schritt (CE) '
          'das Operanden-Byte.',
    ),
    IsaCard.pushPop => const IsaEntry(
      'A auf dem Stapel sichern / wiederherstellen.',
      _none,
      'PUSH schreibt A nach RAM[SP], dann SP = SP - 1. POP macht SP = SP '
          '+ 1, dann A = RAM[SP]. Zuletzt hinein, zuerst heraus.',
    ),
    IsaCard.call => const IsaEntry(
      'Unterprogramm aufrufen.',
      _extAddr,
      'Legt PC (die Adresse seines eigenen Operanden-Bytes) auf den '
          'Stapel und springt dann nach addr.',
    ),
    IsaCard.ret => const IsaEntry(
      'Rückkehr aus einem Unterprogramm.',
      _none,
      'Holt den gesicherten PC vom Stapel, geht dann über das '
          'Operanden-Byte des CALL hinweg (CE) und landet auf dem Befehl '
          'nach dem CALL.',
    ),
    IsaCard.outPort => const IsaEntry(
      'A an das Gerät eines Ports schreiben.',
      _port,
      'Das Operanden-Byte geht ins Portregister (RO|PI|CE), dann treibt A '
          'den Bus und das Gerät dort liest ihn (AO|DI). Einfaches OUT ist '
          'Port 0, die Anzeige.',
      'A -> LCD-Daten: ein Zeichen zeigen',
    ),
    IsaCard.inPort => const IsaEntry(
      'Das Gerät eines Ports nach A lesen.',
      _port,
      'Wählt den Port (RO|PI|CE), dann treibt das Gerät den Bus nach A '
          '(DO|AI). Setzt keine Flags: den Wert mit CMP prüfen. Ein Port '
          'ohne angeschlossenes Gerät liefert 0.',
      'A = zuletzt gedrückte Taste, oder 0',
    ),
    IsaCard.nop => const IsaEntry(
      'Keine Operation - Tut nichts, braucht einen Taktzyklus.',
      _none,
      'Der Programmzähler wird erhöht, aber keine Daten werden bewegt '
          'oder verändert.',
    ),
    IsaCard.hlt => const IsaEntry(
      'Anhalten - Beendet die Programmausführung.',
      _none,
      'Der Takt stoppt und die CPU ist angehalten. Es werden keine '
          'weiteren Befehle ausgeführt.',
    ),
    IsaCard.lda => const IsaEntry(
      'Von Adresse laden - Lädt einen Wert aus dem RAM in Register A.',
      _addr,
      'Liest den Wert an der angegebenen Speicheradresse und speichert ihn '
          'in Register A. Der bisherige Wert von Register A wird '
          'überschrieben.',
      'Wert aus RAM[14] nach A laden',
    ),
    IsaCard.ldi => const IsaEntry(
      'Direkt laden - Lädt einen literalen Wert in Register A.',
      'Direktwert (#0-#15)',
      'Speichert den Direktwert unmittelbar in Register A. '
          'Greift NICHT auf den Speicher zu - der Operand IST der Wert.',
      'Die Zahl 7 nach A laden',
    ),
    IsaCard.sta => const IsaEntry(
      'An Adresse speichern - Speichert den Wert von Register A im RAM.',
      _addr,
      'Schreibt den aktuellen Wert von Register A an die angegebene '
          'Speicheradresse. Der Wert von Register A bleibt unverändert.',
      'Wert von Register A in RAM[13] speichern',
    ),
    IsaCard.add => const IsaEntry(
      'Addieren - Addiert einen Wert aus dem RAM zu Register A.',
      _addr,
      'Liest den Wert an der Speicheradresse, addiert ihn zu Register A, '
          'speichert das Ergebnis in A. Setzt das Übertrags-Flag, wenn '
          'Ergebnis > 255. Setzt das Null-Flag, wenn Ergebnis = 0.',
      'A = A + RAM[15]',
    ),
    IsaCard.sub => const IsaEntry(
      'Subtrahieren - Subtrahiert einen Wert aus dem RAM von Register A.',
      _addr,
      'Liest den Wert an der Speicheradresse, subtrahiert ihn von '
          'Register A, speichert das Ergebnis in A. Setzt das Übertrags-Flag '
          'bei einem Borgen (Wert größer als A, das Ergebnis läuft unter 0). '
          'Setzt das Null-Flag, wenn '
          'Ergebnis = 0.',
      'A = A - RAM[14]',
    ),
    IsaCard.jmp => const IsaEntry(
      'Springen - Springt bedingungslos zur angegebenen Adresse.',
      _addr,
      'Setzt den Programmzähler auf die Operandenadresse. Die Ausführung '
          'geht an dieser Adresse weiter. Für Schleifen und '
          'Funktionsaufrufe.',
      'Zurück zum Programmanfang springen',
    ),
    IsaCard.jc => const IsaEntry(
      'Springen bei Übertrag - Springt nur, wenn das Übertrags-Flag '
          'gesetzt ist.',
      _addr,
      'Ist das Übertrags-Flag = 1, wird der Programmzähler auf die '
          'Operandenadresse gesetzt. Sonst geht es mit dem nächsten Befehl '
          'weiter. Zum Erkennen eines Überlaufs.',
      'Zu Adresse 8 springen, wenn ein Überlauf auftrat',
    ),
    IsaCard.jz => const IsaEntry(
      'Springen bei Null - Springt nur, wenn das Null-Flag gesetzt ist.',
      _addr,
      'Ist das Null-Flag = 1 (letztes ALU-Ergebnis war 0), wird der '
          'Programmzähler auf die Operandenadresse gesetzt. Sonst geht es '
          'mit dem nächsten Befehl weiter. Für bedingte Logik.',
      'Zu Adresse 10 springen, wenn A = 0',
    ),
    IsaCard.out => const IsaEntry(
      'Ausgabe - Zeigt den Wert von Register A an.',
      _none,
      'Sendet den aktuellen Wert von Register A an die Ausgabeanzeige '
          '(Port 0). Der Wert von Register A bleibt unverändert.',
    ),
  };

  @override
  String get portMap => 'Port-Belegung';
  @override
  (String, String) port(int port) => switch (port) {
    0 => ('Anzeige', 'Ausgaberegister: einfaches OUT oder OUT 0'),
    1 => (
      'Text-LCD Befehl',
      '0x01 löschen, 0x0C Anzeige an, 0x80+addr Cursor; IN: Cursoradresse',
    ),
    2 => ('Text-LCD Daten', 'Ein Zeichen am Cursor, der weiterrückt'),
    3 => (
      'LED-Matrix Zeile',
      'Wählt die Zeile (0-7), die das nächste Datenbyte leuchten lässt',
    ),
    4 => (
      'LED-Matrix Daten',
      'Bit 7 = linke LED; danach ist die nächste Zeile gewählt',
    ),
    _ => (
      'Tastenfeld',
      "ASCII der zuletzt gedrückten Taste ('0'-'9', 'A'-'D', '*', '#'), "
          'einmalig; 0, wenn keine',
    ),
  };
  @override
  String get dirIn => 'ein';
  @override
  String get dirOut => 'aus';
  @override
  String get lcdNote =>
      'Das LCD startet mit ausgeschalteter Anzeige, wie der echte HD44780: '
      'zuerst 0x38, dann 0x0C senden. Siehe die Beispielprogramme zu den '
      'E/A-Geräten.';

  @override
  String get syntaxTitle => 'Labels, Konstanten & Daten';
  @override
  String get ruleLabel =>
      'Benennt die Adresse des nächsten Bytes. Als Operand verwendbar.';
  @override
  String get ruleEqu => 'Definiert eine Konstante. Belegt keinen Platz im RAM.';
  @override
  String get ruleDb =>
      'Legt Bytes (0-255) im RAM ab: Zahlen, Zeichen, Zeichenketten, Labels.';
  @override
  String get ruleLiterals => 'Hex-, Binär- und Zeichenliterale.';
  @override
  String get syntaxExample => _example(
    'Konstante: ein Name für eine Zahl',
    'Label: ein Name für eine Adresse',
    'Namen gehen überall, wo Zahlen gehen',
    'Sprung vorwärts zu einem Label',
    'Daten: ein Byte pro Wert',
  );
  @override
  String get syntaxNote =>
      'Nach „Assemblieren & laden“ zeigt der Rand Adresse und erstes Byte '
      'jeder Zeile. Bei Namen zählt Groß-/Kleinschreibung nicht.';

  @override
  String get operandRow => '  ↳ Operand';
}
