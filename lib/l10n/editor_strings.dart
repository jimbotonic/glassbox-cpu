import '../core/builtin_program_list.dart';
import '../core/cpu_mode.dart';
import 'l10n.dart';

/// Text of the program editor, the built-in program browser and list, and
/// the assembler's error messages.
abstract class EditorStrings {
  // Editor panel.
  String get programTitle; // 'PROGRAM'
  String get statusError; // 'error'
  String get statusNotAssembled; // 'not assembled'
  String statusAssembled(int bytes, int ramSize);
  String get placeholder; // 'Enter assembly code here...' and an example
  String get assembleAndLoad;
  String get builtinPrograms;
  String get instructionSet;
  String get toggleBreakpoint;
  String get assemblerLog;
  String lineLabel(int line); // 'line 3'

  // Hint box messages.
  String get startHint;
  String get programModified;
  String modeSwitched(CpuMode mode);
  String assembledFor(CpuMode mode, int bytes, int ramSize);
  String openedFor(CpuMode mode);

  // CPU modes, as the editor names them.
  String modeName(CpuMode mode); // 'Classic'
  String modeDescription(CpuMode mode);

  // Built-in program browser and list.
  String get browserTitle;
  String get browserNote;
  String switchesTo(CpuMode mode); // 'switches to Classic'
  String categoryName(BuiltinProgramCategory category);
  String programName(BuiltinProgramId id);
  String programDescription(BuiltinProgramId id);

  // Assembler errors.
  String errorAtLine(int line, String message); // 'Line 2: ...'
  String unknownDirective(String directive);
  String get programEmpty;
  String programTooBig(int bytes, int ramSize);
  String nameIsInstruction(String name);
  String alreadyDefined(String name);
  String get expectedEqu;
  String unknownInstruction(String keyword);
  String cannotTakeIndexed(String keyword);
  String extendedOnly(String usage);
  String unexpected(String token);
  String requiresOperand(String mnemonic);
  String takesNoOperand(String mnemonic, String got);
  String operand4Bit(int value);
  String value8Bit(int value);
  String port8Bit(int value);
  String address8Bit(int value);
  String get dbNeedsValue;
  String get dbMissingValue;
  String charLiteralLength(String literal);
  String unknownName(String name);
  String invalidOperand(String text);
  String unterminatedLiteral(String literal);
  String notAByte(String char);
  String byteRange(int value);
}

/// The current language's editor text.
EditorStrings get tEditor => L10n.pick(const _En(), const _Fr(), const _De());

/// The English editor text, whatever the current language: built-in
/// programs are looked up by their English name.
const EditorStrings englishEditorStrings = _En();

class _En implements EditorStrings {
  const _En();

  @override
  String get programTitle => 'PROGRAM';
  @override
  String get statusError => 'error';
  @override
  String get statusNotAssembled => 'not assembled';
  @override
  String statusAssembled(int bytes, int ramSize) =>
      'assembled · $bytes of $ramSize bytes';
  @override
  String get placeholder =>
      'Enter assembly code here...\n\n'
      'Example:\n'
      '.equ STEP 1     ; named constant\n'
      'loop: LDA n     ; label\n'
      '      OUT\n'
      '      SUB step\n'
      '      STA n\n'
      '      JZ  done\n'
      '      JMP loop\n'
      'done: HLT\n'
      'n:    .db 5     ; data byte\n'
      'step: .db STEP';
  @override
  String get assembleAndLoad => 'Assemble & load';
  @override
  String get builtinPrograms => 'Built-in programs';
  @override
  String get instructionSet => 'Instruction set';
  @override
  String get toggleBreakpoint => 'Toggle breakpoint';
  @override
  String get assemblerLog => 'Assembler log';
  @override
  String lineLabel(int line) => 'line $line';

  @override
  String get startHint =>
      'Write a program or open a built-in one, then assemble.';
  @override
  String get programModified => 'Program modified. Assemble again to load it.';
  @override
  String modeSwitched(CpuMode mode) =>
      '${mode.label} CPU: ${mode.description}. RAM cleared: assemble again.';
  @override
  String assembledFor(CpuMode mode, int bytes, int ramSize) =>
      'Assembled for ${mode.label}: $bytes of $ramSize bytes, loaded into RAM.';
  @override
  String openedFor(CpuMode mode) =>
      'Opened for the ${mode.label} CPU. Assemble & load to put it in RAM.';

  @override
  String modeName(CpuMode mode) => mode.label;
  @override
  String modeDescription(CpuMode mode) => mode.description;

  @override
  String get browserTitle => 'BUILT-IN PROGRAMS';
  @override
  String get browserNote =>
      'Opens a program in the editor. A program for the other CPU '
      'switches the machine.';
  @override
  String switchesTo(CpuMode mode) => 'switches to ${mode.label}';
  @override
  String categoryName(BuiltinProgramCategory category) => switch (category) {
    BuiltinProgramCategory.beginner => 'Beginner',
    BuiltinProgramCategory.arithmetic => 'Arithmetic',
    BuiltinProgramCategory.controlFlow => 'Control Flow',
    BuiltinProgramCategory.patterns => 'Patterns',
    BuiltinProgramCategory.extended => 'Extended CPU',
    BuiltinProgramCategory.devices => 'I/O devices',
  };
  @override
  String programName(BuiltinProgramId id) => switch (id) {
    BuiltinProgramId.counter => 'Counter (0-255)',
    BuiltinProgramId.binaryBlinker => 'Binary Blinker',
    BuiltinProgramId.fibonacci => 'Fibonacci Sequence',
    BuiltinProgramId.powersOf2 => 'Powers of 2',
    BuiltinProgramId.triangleNumbers => 'Triangle Numbers',
    BuiltinProgramId.squareNumbers => 'Square Numbers',
    BuiltinProgramId.multiplication => 'Multiplication (7 × 3)',
    BuiltinProgramId.countdown => 'Countdown from 10',
    BuiltinProgramId.countdownLabels => 'Countdown (labels & data)',
    BuiltinProgramId.evenNumbers => 'Even Numbers',
    BuiltinProgramId.multiplesOf5 => 'Multiples of 5',
    BuiltinProgramId.alternating => 'Alternating Pattern',
    BuiltinProgramId.countdownImmediates => 'Countdown (immediates & JNZ)',
    BuiltinProgramId.hello => 'Hello (string with LDA [B])',
    BuiltinProgramId.stackReverse => 'Stack reverse (PUSH / POP)',
    BuiltinProgramId.multiply => 'Multiply (CALL, shifts, AND)',
    BuiltinProgramId.bouncingBit => 'Bouncing bit (SHL / SHR)',
    BuiltinProgramId.lcdHello => 'LCD: Hello, world',
    BuiltinProgramId.lcdCustomChar => 'LCD: custom character',
    BuiltinProgramId.ledSmiley => 'LED matrix: smiley',
    BuiltinProgramId.keypadEcho => 'Keypad echo',
  };
  @override
  String programDescription(BuiltinProgramId id) => switch (id) {
    BuiltinProgramId.counter => 'Counts from 0 to 255 continuously',
    BuiltinProgramId.binaryBlinker => 'Alternates between 0 and 1 continuously',
    BuiltinProgramId.fibonacci =>
      'Generates Fibonacci numbers: 0, 1, 1, 2, 3, 5, 8, 13...',
    BuiltinProgramId.powersOf2 =>
      'Generates powers of 2: 1, 2, 4, 8, 16, 32, 64, 128...',
    BuiltinProgramId.triangleNumbers =>
      'Generates triangle numbers: 1, 3, 6, 10, 15, 21, 28...',
    BuiltinProgramId.squareNumbers =>
      'Generates squares: 1, 4, 9, 16, 25, 36, 49, 64...',
    BuiltinProgramId.multiplication =>
      'Multiplies 7 by 3 using repeated addition, outputs 21',
    BuiltinProgramId.countdown => 'Counts down from 10 to 0 and halts',
    BuiltinProgramId.countdownLabels =>
      'The countdown again, with labels, a constant and data bytes '
          'instead of raw addresses',
    BuiltinProgramId.evenNumbers =>
      'Outputs even numbers: 0, 2, 4, 6, 8, 10...',
    BuiltinProgramId.multiplesOf5 =>
      'Outputs multiples of 5: 0, 5, 10, 15, 20, 25...',
    BuiltinProgramId.alternating => 'Alternates between 10 and 20',
    BuiltinProgramId.countdownImmediates =>
      'Counts down from 10 with SBI and JNZ: no data bytes needed. '
          'Extended CPU',
    BuiltinProgramId.hello =>
      'Walks a zero-terminated string with an index in B and outputs '
          'each character code: 72 69 76 76 79. Extended CPU',
    BuiltinProgramId.stackReverse =>
      'Pushes 1, 2, 3 and pops them back: the stack gives them in '
          'reverse, 3 2 1. Extended CPU',
    BuiltinProgramId.multiply =>
      'A shift-and-add multiply subroutine: 13 × 11 = 143. Extended CPU',
    BuiltinProgramId.bouncingBit =>
      'A lit bit runs left to bit 7 and back: 1 2 4 … 128 64 … 1. '
          'The carry flag catches the bit that falls off. Extended CPU',
    BuiltinProgramId.lcdHello =>
      'Initialises the 16x2 LCD, then writes two lines from a string '
          'with OUT 2. A newline byte moves to line 2.',
    BuiltinProgramId.lcdCustomChar =>
      'Draws a heart in CGRAM as character 0, then prints it between '
          'words: "I <heart> CPU".',
    BuiltinProgramId.ledSmiley =>
      'Selects row 0, then writes eight row bytes to the 8x8 matrix; it '
          'moves to the next row after each one.',
    BuiltinProgramId.keypadEcho =>
      'Waits for keypad presses (IN 5) and shows each key on the LCD '
          'and the display. Runs until reset; try a faster clock.',
  };

  @override
  String errorAtLine(int line, String message) => 'Line $line: $message';
  @override
  String unknownDirective(String directive) => 'Unknown directive "$directive"';
  @override
  String get programEmpty => 'Program is empty';
  @override
  String programTooBig(int bytes, int ramSize) =>
      'Program needs $bytes bytes but RAM holds only $ramSize';
  @override
  String nameIsInstruction(String name) =>
      '"$name" is an instruction and cannot be a name';
  @override
  String alreadyDefined(String name) => '"$name" is already defined';
  @override
  String get expectedEqu => 'Expected ".equ NAME value"';
  @override
  String unknownInstruction(String keyword) => 'Unknown instruction "$keyword"';
  @override
  String cannotTakeIndexed(String keyword) =>
      '$keyword cannot take [B]; only LDA [B] is indexed';
  @override
  String extendedOnly(String usage) => '$usage exists only in Extended mode';
  @override
  String unexpected(String token) => 'Unexpected "$token"';
  @override
  String requiresOperand(String mnemonic) => '$mnemonic requires an operand';
  @override
  String takesNoOperand(String mnemonic, String got) =>
      '$mnemonic takes no operand, got "$got"';
  @override
  String operand4Bit(int value) => 'Operand must be 0-15 (4-bit), got $value';
  @override
  String value8Bit(int value) => 'Value must be -128..255 (8-bit), got $value';
  @override
  String port8Bit(int value) => 'Port must be 0-255, got $value';
  @override
  String address8Bit(int value) => 'Address must be 0-255 (8-bit), got $value';
  @override
  String get dbNeedsValue => '.db needs at least one value';
  @override
  String get dbMissingValue => 'Missing value in .db';
  @override
  String charLiteralLength(String literal) =>
      'Character literal $literal must hold one character';
  @override
  String unknownName(String name) => 'Unknown name "$name"';
  @override
  String invalidOperand(String text) => 'Invalid operand "$text"';
  @override
  String unterminatedLiteral(String literal) => 'Unterminated literal $literal';
  @override
  String notAByte(String char) => '"$char" does not fit in a byte';
  @override
  String byteRange(int value) => 'Byte must be -128..255, got $value';
}

class _Fr implements EditorStrings {
  const _Fr();

  @override
  String get programTitle => 'PROGRAMME';
  @override
  String get statusError => 'erreur';
  @override
  String get statusNotAssembled => 'non assemblé';
  @override
  String statusAssembled(int bytes, int ramSize) =>
      'assemblé · $bytes octets sur $ramSize';
  @override
  String get placeholder =>
      'Saisir le code assembleur ici...\n\n'
      'Exemple\u202F:\n'
      '.equ STEP 1     ; constante nommée\n'
      'loop: LDA n     ; étiquette\n'
      '      OUT\n'
      '      SUB step\n'
      '      STA n\n'
      '      JZ  done\n'
      '      JMP loop\n'
      'done: HLT\n'
      'n:    .db 5     ; octet de données\n'
      'step: .db STEP';
  @override
  String get assembleAndLoad => 'Assembler et charger';
  @override
  String get builtinPrograms => 'Programmes intégrés';
  @override
  String get instructionSet => "Jeu d'instructions";
  @override
  String get toggleBreakpoint => "Basculer le point d'arrêt";
  @override
  String get assemblerLog => "Journal de l'assembleur";
  @override
  String lineLabel(int line) => 'ligne $line';

  @override
  String get startHint =>
      'Écrire un programme ou ouvrir un programme intégré, puis assembler.';
  @override
  String get programModified =>
      'Programme modifié. Assembler à nouveau pour le charger.';
  @override
  String modeSwitched(CpuMode mode) =>
      'CPU ${modeName(mode)}\u202F: ${modeDescription(mode)}. '
      'RAM effacée\u202F: assembler à nouveau.';
  @override
  String assembledFor(CpuMode mode, int bytes, int ramSize) =>
      'Assemblé pour ${modeName(mode)}\u202F: $bytes octets sur $ramSize, '
      'chargés en RAM.';
  @override
  String openedFor(CpuMode mode) =>
      'Ouvert pour le CPU ${modeName(mode)}. '
      '«\u202FAssembler et charger\u202F» le met en RAM.';

  @override
  String modeName(CpuMode mode) => switch (mode) {
    CpuMode.classic => 'Classique',
    CpuMode.extended => 'Étendu',
  };
  @override
  String modeDescription(CpuMode mode) => switch (mode) {
    CpuMode.classic => '16 octets de RAM, opérandes de 4 bits, 11 instructions',
    CpuMode.extended =>
      "256 octets de RAM, opérandes de 8 bits, pile, ports d'E/S, "
          '29 instructions',
  };

  @override
  String get browserTitle => 'PROGRAMMES INTÉGRÉS';
  @override
  String get browserNote =>
      "Ouvre un programme dans l'éditeur. Un programme pour l'autre CPU "
      'change de machine.';
  @override
  String switchesTo(CpuMode mode) => 'passe en ${modeName(mode)}';
  @override
  String categoryName(BuiltinProgramCategory category) => switch (category) {
    BuiltinProgramCategory.beginner => 'Débutant',
    BuiltinProgramCategory.arithmetic => 'Arithmétique',
    BuiltinProgramCategory.controlFlow => 'Flux de contrôle',
    BuiltinProgramCategory.patterns => 'Motifs',
    BuiltinProgramCategory.extended => 'CPU étendu',
    BuiltinProgramCategory.devices => 'Périphériques E/S',
  };
  @override
  String programName(BuiltinProgramId id) => switch (id) {
    BuiltinProgramId.counter => 'Compteur (0-255)',
    BuiltinProgramId.binaryBlinker => 'Clignotant binaire',
    BuiltinProgramId.fibonacci => 'Suite de Fibonacci',
    BuiltinProgramId.powersOf2 => 'Puissances de 2',
    BuiltinProgramId.triangleNumbers => 'Nombres triangulaires',
    BuiltinProgramId.squareNumbers => 'Carrés',
    BuiltinProgramId.multiplication => 'Multiplication (7 × 3)',
    BuiltinProgramId.countdown => 'Compte à rebours depuis 10',
    BuiltinProgramId.countdownLabels =>
      'Compte à rebours (étiquettes et données)',
    BuiltinProgramId.evenNumbers => 'Nombres pairs',
    BuiltinProgramId.multiplesOf5 => 'Multiples de 5',
    BuiltinProgramId.alternating => 'Motif alterné',
    BuiltinProgramId.countdownImmediates =>
      'Compte à rebours (immédiats et JNZ)',
    BuiltinProgramId.hello => 'Hello (chaîne avec LDA [B])',
    BuiltinProgramId.stackReverse => 'Inversion par la pile (PUSH / POP)',
    BuiltinProgramId.multiply => 'Multiplication (CALL, décalages, AND)',
    BuiltinProgramId.bouncingBit => 'Bit rebondissant (SHL / SHR)',
    BuiltinProgramId.lcdHello => 'LCD\u202F: Hello, world',
    BuiltinProgramId.lcdCustomChar => 'LCD\u202F: caractère personnalisé',
    BuiltinProgramId.ledSmiley => 'Matrice de LED\u202F: smiley',
    BuiltinProgramId.keypadEcho => 'Écho du clavier',
  };
  @override
  String programDescription(BuiltinProgramId id) => switch (id) {
    BuiltinProgramId.counter => 'Compte de 0 à 255 en boucle',
    BuiltinProgramId.binaryBlinker => 'Alterne entre 0 et 1 en boucle',
    BuiltinProgramId.fibonacci =>
      'Génère les nombres de Fibonacci\u202F: 0, 1, 1, 2, 3, 5, 8, 13...',
    BuiltinProgramId.powersOf2 =>
      'Génère les puissances de 2\u202F: 1, 2, 4, 8, 16, 32, 64, 128...',
    BuiltinProgramId.triangleNumbers =>
      'Génère les nombres triangulaires\u202F: 1, 3, 6, 10, 15, 21, 28...',
    BuiltinProgramId.squareNumbers =>
      'Génère les carrés\u202F: 1, 4, 9, 16, 25, 36, 49, 64...',
    BuiltinProgramId.multiplication =>
      'Multiplie 7 par 3 par additions successives, affiche 21',
    BuiltinProgramId.countdown => "Compte de 10 à 0 et s'arrête",
    BuiltinProgramId.countdownLabels =>
      'Le même compte à rebours, avec des étiquettes, une constante et des '
          "octets de données au lieu d'adresses brutes",
    BuiltinProgramId.evenNumbers =>
      'Affiche les nombres pairs\u202F: 0, 2, 4, 6, 8, 10...',
    BuiltinProgramId.multiplesOf5 =>
      'Affiche les multiples de 5\u202F: 0, 5, 10, 15, 20, 25...',
    BuiltinProgramId.alternating => 'Alterne entre 10 et 20',
    BuiltinProgramId.countdownImmediates =>
      'Compte à rebours depuis 10 avec SBI et JNZ\u202F: aucun octet de '
          'données nécessaire. CPU étendu',
    BuiltinProgramId.hello =>
      'Parcourt une chaîne terminée par zéro avec un index dans B et '
          'affiche le code de chaque caractère\u202F: 72 69 76 76 79. '
          'CPU étendu',
    BuiltinProgramId.stackReverse =>
      'Empile 1, 2, 3 puis les dépile\u202F: la pile les rend dans '
          "l'ordre inverse, 3 2 1. CPU étendu",
    BuiltinProgramId.multiply =>
      'Un sous-programme de multiplication par décalages et additions\u202F: '
          '13 × 11 = 143. CPU étendu',
    BuiltinProgramId.bouncingBit =>
      "Un bit allumé va à gauche jusqu'au bit 7 et revient\u202F: "
          '1 2 4 … 128 64 … 1. '
          "L'indicateur de retenue recueille le bit qui sort. CPU étendu",
    BuiltinProgramId.lcdHello =>
      "Initialise l'écran LCD 16x2, puis écrit deux lignes depuis une "
          'chaîne avec OUT 2. Un octet de saut de ligne passe à la ligne 2.',
    BuiltinProgramId.lcdCustomChar =>
      "Dessine un cœur en CGRAM comme caractère 0, puis l'affiche entre "
          'deux mots\u202F: «\u202FI <cœur> CPU\u202F».',
    BuiltinProgramId.ledSmiley =>
      'Sélectionne la ligne 0, puis écrit huit octets de ligne dans la '
          'matrice 8x8\u202F; elle passe à la ligne suivante après chacun.',
    BuiltinProgramId.keypadEcho =>
      'Attend les appuis sur le clavier (IN 5) et affiche chaque touche sur '
          "l'écran LCD et l'afficheur. Tourne jusqu'à la réinitialisation\u202F; "
          'essayer une horloge plus rapide.',
  };

  @override
  String errorAtLine(int line, String message) => 'Ligne $line\u202F: $message';
  @override
  String unknownDirective(String directive) =>
      'Directive inconnue «\u202F$directive\u202F»';
  @override
  String get programEmpty => 'Le programme est vide';
  @override
  String programTooBig(int bytes, int ramSize) =>
      "Le programme occupe $bytes octets mais la RAM n'en contient "
      'que $ramSize';
  @override
  String nameIsInstruction(String name) =>
      '«\u202F$name\u202F» est une instruction et ne peut pas servir de nom';
  @override
  String alreadyDefined(String name) => '«\u202F$name\u202F» est déjà défini';
  @override
  String get expectedEqu => 'Attendu\u202F: «\u202F.equ NOM valeur\u202F»';
  @override
  String unknownInstruction(String keyword) =>
      'Instruction inconnue «\u202F$keyword\u202F»';
  @override
  String cannotTakeIndexed(String keyword) =>
      "$keyword n'accepte pas [B]\u202F; seul LDA [B] est indexé";
  @override
  String extendedOnly(String usage) => "$usage n'existe qu'en mode Étendu";
  @override
  String unexpected(String token) => 'Inattendu\u202F: «\u202F$token\u202F»';
  @override
  String requiresOperand(String mnemonic) => '$mnemonic demande un opérande';
  @override
  String takesNoOperand(String mnemonic, String got) =>
      "$mnemonic ne prend pas d'opérande, reçu «\u202F$got\u202F»";
  @override
  String operand4Bit(int value) =>
      "L'opérande doit valoir 0-15 (4 bits), reçu $value";
  @override
  String value8Bit(int value) =>
      'La valeur doit valoir -128..255 (8 bits), reçu $value';
  @override
  String port8Bit(int value) => 'Le port doit valoir 0-255, reçu $value';
  @override
  String address8Bit(int value) =>
      "L'adresse doit valoir 0-255 (8 bits), reçu $value";
  @override
  String get dbNeedsValue => '.db demande au moins une valeur';
  @override
  String get dbMissingValue => 'Valeur manquante dans .db';
  @override
  String charLiteralLength(String literal) =>
      'Le littéral caractère $literal doit contenir un seul caractère';
  @override
  String unknownName(String name) => 'Nom inconnu «\u202F$name\u202F»';
  @override
  String invalidOperand(String text) => 'Opérande invalide «\u202F$text\u202F»';
  @override
  String unterminatedLiteral(String literal) => 'Littéral non terminé $literal';
  @override
  String notAByte(String char) =>
      '«\u202F$char\u202F» ne tient pas dans un octet';
  @override
  String byteRange(int value) => "L'octet doit valoir -128..255, reçu $value";
}

class _De implements EditorStrings {
  const _De();

  @override
  String get programTitle => 'PROGRAMM';
  @override
  String get statusError => 'Fehler';
  @override
  String get statusNotAssembled => 'nicht assembliert';
  @override
  String statusAssembled(int bytes, int ramSize) =>
      'assembliert · $bytes von $ramSize Byte';
  @override
  String get placeholder =>
      'Assemblercode hier eingeben...\n\n'
      'Beispiel:\n'
      '.equ STEP 1     ; benannte Konstante\n'
      'loop: LDA n     ; Label\n'
      '      OUT\n'
      '      SUB step\n'
      '      STA n\n'
      '      JZ  done\n'
      '      JMP loop\n'
      'done: HLT\n'
      'n:    .db 5     ; Datenbyte\n'
      'step: .db STEP';
  @override
  String get assembleAndLoad => 'Assemblieren & laden';
  @override
  String get builtinPrograms => 'Beispielprogramme';
  @override
  String get instructionSet => 'Befehlssatz';
  @override
  String get toggleBreakpoint => 'Haltepunkt umschalten';
  @override
  String get assemblerLog => 'Assembler-Protokoll';
  @override
  String lineLabel(int line) => 'Zeile $line';

  @override
  String get startHint =>
      'Ein Programm schreiben oder ein Beispielprogramm öffnen, '
      'dann assemblieren.';
  @override
  String get programModified =>
      'Programm geändert. Zum Laden neu assemblieren.';
  @override
  String modeSwitched(CpuMode mode) =>
      'CPU „${modeName(mode)}“: ${modeDescription(mode)}. '
      'RAM gelöscht: neu assemblieren.';
  @override
  String assembledFor(CpuMode mode, int bytes, int ramSize) =>
      'Assembliert für „${modeName(mode)}“: $bytes von $ramSize Byte, '
      'in den RAM geladen.';
  @override
  String openedFor(CpuMode mode) =>
      'Für die CPU „${modeName(mode)}“ geöffnet. '
      '„Assemblieren & laden“ bringt es in den RAM.';

  @override
  String modeName(CpuMode mode) => switch (mode) {
    CpuMode.classic => 'Klassisch',
    CpuMode.extended => 'Erweitert',
  };
  @override
  String modeDescription(CpuMode mode) => switch (mode) {
    CpuMode.classic => '16 Byte RAM, 4-Bit-Operanden, 11 Befehle',
    CpuMode.extended =>
      '256 Byte RAM, 8-Bit-Operanden, Stapel, E/A-Ports, 29 Befehle',
  };

  @override
  String get browserTitle => 'BEISPIELPROGRAMME';
  @override
  String get browserNote =>
      'Öffnet ein Programm im Editor. Ein Programm für die andere CPU '
      'wechselt die Maschine.';
  @override
  String switchesTo(CpuMode mode) => 'wechselt zu ${modeName(mode)}';
  @override
  String categoryName(BuiltinProgramCategory category) => switch (category) {
    BuiltinProgramCategory.beginner => 'Einstieg',
    BuiltinProgramCategory.arithmetic => 'Arithmetik',
    BuiltinProgramCategory.controlFlow => 'Kontrollfluss',
    BuiltinProgramCategory.patterns => 'Muster',
    BuiltinProgramCategory.extended => 'Erweiterte CPU',
    BuiltinProgramCategory.devices => 'E/A-Geräte',
  };
  @override
  String programName(BuiltinProgramId id) => switch (id) {
    BuiltinProgramId.counter => 'Zähler (0-255)',
    BuiltinProgramId.binaryBlinker => 'Binärer Blinker',
    BuiltinProgramId.fibonacci => 'Fibonacci-Folge',
    BuiltinProgramId.powersOf2 => 'Zweierpotenzen',
    BuiltinProgramId.triangleNumbers => 'Dreieckszahlen',
    BuiltinProgramId.squareNumbers => 'Quadratzahlen',
    BuiltinProgramId.multiplication => 'Multiplikation (7 × 3)',
    BuiltinProgramId.countdown => 'Countdown ab 10',
    BuiltinProgramId.countdownLabels => 'Countdown (Labels & Daten)',
    BuiltinProgramId.evenNumbers => 'Gerade Zahlen',
    BuiltinProgramId.multiplesOf5 => 'Vielfache von 5',
    BuiltinProgramId.alternating => 'Wechselmuster',
    BuiltinProgramId.countdownImmediates => 'Countdown (Direktwerte & JNZ)',
    BuiltinProgramId.hello => 'Hello (String mit LDA [B])',
    BuiltinProgramId.stackReverse => 'Stapel umkehren (PUSH / POP)',
    BuiltinProgramId.multiply => 'Multiplikation (CALL, Shifts, AND)',
    BuiltinProgramId.bouncingBit => 'Springendes Bit (SHL / SHR)',
    BuiltinProgramId.lcdHello => 'LCD: Hello, world',
    BuiltinProgramId.lcdCustomChar => 'LCD: eigenes Zeichen',
    BuiltinProgramId.ledSmiley => 'LED-Matrix: Smiley',
    BuiltinProgramId.keypadEcho => 'Tastenfeld-Echo',
  };
  @override
  String programDescription(BuiltinProgramId id) => switch (id) {
    BuiltinProgramId.counter => 'Zählt fortlaufend von 0 bis 255',
    BuiltinProgramId.binaryBlinker => 'Wechselt fortlaufend zwischen 0 und 1',
    BuiltinProgramId.fibonacci =>
      'Erzeugt Fibonacci-Zahlen: 0, 1, 1, 2, 3, 5, 8, 13...',
    BuiltinProgramId.powersOf2 =>
      'Erzeugt Zweierpotenzen: 1, 2, 4, 8, 16, 32, 64, 128...',
    BuiltinProgramId.triangleNumbers =>
      'Erzeugt Dreieckszahlen: 1, 3, 6, 10, 15, 21, 28...',
    BuiltinProgramId.squareNumbers =>
      'Erzeugt Quadratzahlen: 1, 4, 9, 16, 25, 36, 49, 64...',
    BuiltinProgramId.multiplication =>
      'Multipliziert 7 mit 3 durch wiederholte Addition, gibt 21 aus',
    BuiltinProgramId.countdown => 'Zählt von 10 auf 0 herunter und hält an',
    BuiltinProgramId.countdownLabels =>
      'Noch einmal der Countdown, mit Labels, einer Konstante und '
          'Datenbytes statt fester Adressen',
    BuiltinProgramId.evenNumbers =>
      'Gibt gerade Zahlen aus: 0, 2, 4, 6, 8, 10...',
    BuiltinProgramId.multiplesOf5 =>
      'Gibt Vielfache von 5 aus: 0, 5, 10, 15, 20, 25...',
    BuiltinProgramId.alternating => 'Wechselt zwischen 10 und 20',
    BuiltinProgramId.countdownImmediates =>
      'Zählt mit SBI und JNZ von 10 herunter: keine Datenbytes nötig. '
          'Erweiterte CPU',
    BuiltinProgramId.hello =>
      'Durchläuft einen nullterminierten String mit einem Index in B und '
          'gibt jeden Zeichencode aus: 72 69 76 76 79. Erweiterte CPU',
    BuiltinProgramId.stackReverse =>
      'Legt 1, 2, 3 auf den Stapel und holt sie zurück: der Stapel liefert '
          'sie umgekehrt, 3 2 1. Erweiterte CPU',
    BuiltinProgramId.multiply =>
      'Ein Unterprogramm, das durch Schieben und Addieren multipliziert: '
          '13 × 11 = 143. Erweiterte CPU',
    BuiltinProgramId.bouncingBit =>
      'Ein gesetztes Bit läuft nach links bis Bit 7 und zurück: '
          '1 2 4 … 128 64 … 1. '
          'Das Übertrag-Flag fängt das herausfallende Bit auf. Erweiterte CPU',
    BuiltinProgramId.lcdHello =>
      'Initialisiert das 16x2-LCD und schreibt dann mit OUT 2 zwei Zeilen '
          'aus einem String. Ein Zeilenumbruch-Byte wechselt in Zeile 2.',
    BuiltinProgramId.lcdCustomChar =>
      'Zeichnet ein Herz im CGRAM als Zeichen 0 und gibt es zwischen '
          'Wörtern aus: „I <Herz> CPU“.',
    BuiltinProgramId.ledSmiley =>
      'Wählt Zeile 0 und schreibt dann acht Zeilenbytes in die 8x8-Matrix; '
          'nach jedem wechselt sie zur nächsten Zeile.',
    BuiltinProgramId.keypadEcho =>
      'Wartet auf Tastendrücke (IN 5) und zeigt jede Taste auf dem LCD und '
          'der Anzeige. Läuft bis zum Zurücksetzen; ein schnellerer Takt '
          'lohnt sich.',
  };

  @override
  String errorAtLine(int line, String message) => 'Zeile $line: $message';
  @override
  String unknownDirective(String directive) =>
      'Unbekannte Direktive „$directive“';
  @override
  String get programEmpty => 'Programm ist leer';
  @override
  String programTooBig(int bytes, int ramSize) =>
      'Programm braucht $bytes Byte, der RAM fasst nur $ramSize';
  @override
  String nameIsInstruction(String name) =>
      '„$name“ ist ein Befehl und kann kein Name sein';
  @override
  String alreadyDefined(String name) => '„$name“ ist bereits definiert';
  @override
  String get expectedEqu => 'Erwartet: „.equ NAME Wert“';
  @override
  String unknownInstruction(String keyword) => 'Unbekannter Befehl „$keyword“';
  @override
  String cannotTakeIndexed(String keyword) =>
      '$keyword kann kein [B] nehmen; nur LDA [B] ist indiziert';
  @override
  String extendedOnly(String usage) => '$usage gibt es nur im Modus Erweitert';
  @override
  String unexpected(String token) => 'Unerwartet: „$token“';
  @override
  String requiresOperand(String mnemonic) =>
      '$mnemonic braucht einen Operanden';
  @override
  String takesNoOperand(String mnemonic, String got) =>
      '$mnemonic nimmt keinen Operanden, erhalten: „$got“';
  @override
  String operand4Bit(int value) =>
      'Operand muss 0-15 sein (4 Bit), erhalten: $value';
  @override
  String value8Bit(int value) =>
      'Wert muss -128..255 sein (8 Bit), erhalten: $value';
  @override
  String port8Bit(int value) => 'Port muss 0-255 sein, erhalten: $value';
  @override
  String address8Bit(int value) =>
      'Adresse muss 0-255 sein (8 Bit), erhalten: $value';
  @override
  String get dbNeedsValue => '.db braucht mindestens einen Wert';
  @override
  String get dbMissingValue => 'Fehlender Wert in .db';
  @override
  String charLiteralLength(String literal) =>
      'Zeichenliteral $literal muss genau ein Zeichen enthalten';
  @override
  String unknownName(String name) => 'Unbekannter Name „$name“';
  @override
  String invalidOperand(String text) => 'Ungültiger Operand „$text“';
  @override
  String unterminatedLiteral(String literal) =>
      'Nicht abgeschlossenes Literal $literal';
  @override
  String notAByte(String char) => '„$char“ passt nicht in ein Byte';
  @override
  String byteRange(int value) => 'Byte muss -128..255 sein, erhalten: $value';
}
