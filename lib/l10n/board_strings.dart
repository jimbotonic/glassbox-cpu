import 'l10n.dart';

/// Text of the board: the datapath cards, RAM, display, I/O devices, and
/// the real-hardware dialog and bridge.
abstract class BoardStrings {
  // ------------------------------------------------------------ datapath
  String get programCounter; // 'PROGRAM COUNTER'
  String get memoryAddress; // 'MEMORY ADDRESS'
  String get instruction; // 'INSTRUCTION'
  String get stackPointer; // 'STACK POINTER'
  String get registerA; // 'A REGISTER'
  String get registerB; // 'B REGISTER'
  String get alu; // 'ALU · Σ'
  String get outputRegister; // 'OUTPUT REGISTER'
  String get ioPort; // 'I/O PORT'
  String get flags; // 'FLAGS'

  /// `4-bit`: width of a register, as its idle role label.
  String bitsWide(int bits);
  String get ramPortIdle; // 'port'
  String get accumulator; // 'accumulator'
  String get operand; // 'operand'
  String get operandIndex; // 'operand · index'

  /// `port 0`
  String port(int port);

  String get stopped; // 'stopped'
  String next(String instruction); // 'next: LDA 14'
  String selectsRam(String address, String? symbol);
  String get irEmpty; // 'empty until the first fetch'
  String irExtended(String instruction, String? operandAddress);
  String irClassic(String instruction, int opcode, int operand);
  String get stackEmpty; // 'empty · grows down'
  String stackBytes(int bytes); // '2 bytes on the stack'
  String aluNote(String operation, int value, bool carry);
  String outputNote(String value); // '42 · drives the display'
  String portToBus(String name, String hex); // 'keypad → bus: 0x31'
  String portNote(int port, String name); // 'port 5 · keypad'

  String get busIdle; // 'nothing drives the bus this step'
  String busWho(String source, List<String> readers); // 'RAM drives · A reads'

  String get flagsLatchedWire; // 'FI · flags latched from the ALU'
  String get flagsInWire; // 'FI · flags in, from the ALU result'
  String get carry; // 'carry'
  String get zero; // 'zero'
  String get kept; // 'kept'
  String get latched; // 'LATCHED'
  String flagsDecide(String jumps); // '→ microcode: decides JC, JZ'

  String get display; // 'DISPLAY'
  String valueCount(int count); // '3 values'
  String displaySemantics(int value); // 'Display: 42'
  String get displayEmpty; // 'nothing output yet\nOUT copies A here'
  String get asText; // 'as text'
  String get newestFirst; // 'newest first'

  // --------------------------------------------------------- role labels
  String get drivesBus; // 'DRIVES BUS ▸'
  String get readsBus; // '◂ READS BUS'
  String get counts; // 'COUNTS'
  String get close; // 'Close'

  // ----------------------------------------------------------------- RAM
  String get ram; // 'RAM'
  String ramSummary(int bytes, int addressBits);
  String get goToPc; // 'Go to PC'
  String get goToSp; // 'Go to SP'

  String get enterValue; // 'Please enter a value'
  String get invalidInput;
  String valueOutOfRange(int value);
  String editTitle(String address); // 'EDIT RAM[0x3]'
  String editNote(String hex, int value);
  String get inputLabel; // 'Instruction / hex / decimal'
  String get operandNote;
  String get cancel; // 'Cancel'
  String get save; // 'Save'

  // ------------------------------------------------------------- devices
  String get ioDevices; // 'I/O DEVICES'
  String get ioDevicesNote;
  String boardButton(String board); // 'Board: uno'
  String get connecting; // 'Connecting…'
  String get realHardware; // 'Real hardware'
  String mirroredTo(String link);
  String get mirrorTooltip;
  String devicePort(int port, String name); // 'port 5 · keypad'
  String devicePorts(String ports, String roles); // 'ports 1–2 · command, data'
  String get lcdOff; // 'display off · send 0x0C to turn it on'
  String lcdCursor(String hex); // 'cursor 0x00'
  String get writesRight; // 'writes go right'
  String get writesLeft; // 'writes go left'
  String shifted(int by); // 'shifted 2'
  String matrixSemantics(String rows); // 'LED matrix rows: …'
  String keyTooltip(String key, String hex); // 'Press 1: IN reads 0x31'
  String get noKey; // 'no key waiting · IN reads 0'
  String keyWaiting(String key, String hex);

  // ------------------------------------------------- device and port names
  String get textLcd; // 'Text LCD'
  String get keypad; // 'Keypad'
  String get ledMatrix; // 'LED matrix'
  String get lcdCommandPort; // 'LCD command'
  String get lcdDataPort; // 'LCD data'
  String get matrixRowPort; // 'matrix row'
  String get matrixDataPort; // 'matrix data'
  String get keypadPort; // 'keypad'
  String get displayPort; // 'display'
  String get nothingConnected; // 'nothing connected'
  String get commandRole; // 'command'
  String get dataRole; // 'data'
  String get rowRole; // 'row'

  /// Label of a part a board reports, by its protocol name (`lcd`, …).
  String hardwarePart(String part);

  // -------------------------------------------------------------- bridge
  String connectingTo(String link);
  String linkError(Object error);
  String linkClosed(String link);
  String get noAnswer;
  String protocolMismatch(int board, int ours);
  String connectedNote(String board, List<String> parts);
  String failed(String message);
  String disconnectedFrom(String link);
  String get cannotKeepUp;
  String noAnswerLines(int lines);
  String sendFailed(Object error);
  String boardRefused(String message);
  String boardLog(String message);
  String keyNotOnPad(String key);

  // ------------------------------------------------------- hardware links
  String get serialUnavailable;
  String get serialLibraryMissing;
  String get serialNeedsBuild;
  String get chooseSerialPort;
  String cannotOpenPort(String name, String? error, bool linux);
  String writeFailed(String name);
  String get enterAddress;
  String useWs(String scheme);
  String get noHost;
  String noWebSocket(String uri);
  String get noWebSerial;
  String get usbSerial; // 'USB serial'
  String cannotOpenBrowserPort(Object error);
  String get portClosed;

  // ----------------------------------------------------- hardware dialog
  String get realHardwareTitle; // 'REAL HARDWARE'
  String get hardwareNote;
  String get connection; // 'Connection'
  String get wifi; // 'Wi-Fi'
  String get log; // 'Log'
  String get resendState;
  String get resendTooltip;
  String get disconnect;
  String get connect;
  String get browserPickerHint;
  String get portLabel; // 'Port'
  String get noSerialPort;
  String get refresh;
  String get refreshTooltip;
  String get speed;
  String baud(int rate, bool firmwareDefault);
  String get boardAddress;
  String get addressHint;
  String get mixedContent;
  String connectedTo(String board);
  String get noPartsReported;
  String get notConnected;
  String get worksWithoutBoard;
  String get inStep;
  String toSend(int lines);
  String get nothingToChoose;
}

/// The current language's board text.
BoardStrings get tBoard => L10n.pick(const _En(), const _Fr(), const _De());

class _En implements BoardStrings {
  const _En();

  @override
  String get programCounter => 'PROGRAM COUNTER';
  @override
  String get memoryAddress => 'MEMORY ADDRESS';
  @override
  String get instruction => 'INSTRUCTION';
  @override
  String get stackPointer => 'STACK POINTER';
  @override
  String get registerA => 'A REGISTER';
  @override
  String get registerB => 'B REGISTER';
  @override
  String get alu => 'ALU · Σ';
  @override
  String get outputRegister => 'OUTPUT REGISTER';
  @override
  String get ioPort => 'I/O PORT';
  @override
  String get flags => 'FLAGS';
  @override
  String bitsWide(int bits) => '$bits-bit';
  @override
  String get ramPortIdle => 'port';
  @override
  String get accumulator => 'accumulator';
  @override
  String get operand => 'operand';
  @override
  String get operandIndex => 'operand · index';
  @override
  String port(int port) => 'port $port';
  @override
  String get stopped => 'stopped';
  @override
  String next(String instruction) => 'next: $instruction';
  @override
  String selectsRam(String address, String? symbol) =>
      'selects RAM[$address]${symbol == null ? '' : ' · $symbol'}';
  @override
  String get irEmpty => 'empty until the first fetch';
  @override
  String irExtended(String instruction, String? operandAddress) =>
      '$instruction'
      '${operandAddress == null ? '' : ' · operand at $operandAddress'}';
  @override
  String irClassic(String instruction, int opcode, int operand) =>
      '$instruction · opcode $opcode · operand $operand';
  @override
  String get stackEmpty => 'empty · grows down';
  @override
  String stackBytes(int bytes) =>
      '$bytes byte${bytes == 1 ? '' : 's'} on the stack';
  @override
  String aluNote(String operation, int value, bool carry) =>
      '$operation = $value${carry ? ' · carry out' : ''}';
  @override
  String outputNote(String value) => '$value · drives the display';
  @override
  String portToBus(String name, String hex) => '$name → bus: $hex';
  @override
  String portNote(int port, String name) => 'port $port · $name';
  @override
  String get busIdle => 'nothing drives the bus this step';
  @override
  String busWho(String source, List<String> readers) =>
      '$source drives'
      '${readers.isEmpty ? '' : ' · ${readers.join(', ')} read${readers.length == 1 ? 's' : ''}'}';
  @override
  String get flagsLatchedWire => 'FI · flags latched from the ALU';
  @override
  String get flagsInWire => 'FI · flags in, from the ALU result';
  @override
  String get carry => 'carry';
  @override
  String get zero => 'zero';
  @override
  String get kept => 'kept';
  @override
  String get latched => 'LATCHED';
  @override
  String flagsDecide(String jumps) => '→ microcode: decides $jumps';
  @override
  String get display => 'DISPLAY';
  @override
  String valueCount(int count) => '$count value${count == 1 ? '' : 's'}';
  @override
  String displaySemantics(int value) => 'Display: $value';
  @override
  String get displayEmpty => 'nothing output yet\nOUT copies A here';
  @override
  String get asText => 'as text';
  @override
  String get newestFirst => 'newest first';

  @override
  String get drivesBus => 'DRIVES BUS ▸';
  @override
  String get readsBus => '◂ READS BUS';
  @override
  String get counts => 'COUNTS';
  @override
  String get close => 'Close';

  @override
  String get ram => 'RAM';
  @override
  String ramSummary(int bytes, int addressBits) =>
      '$bytes bytes · $addressBits-bit addresses · tap to edit';
  @override
  String get goToPc => 'Go to PC';
  @override
  String get goToSp => 'Go to SP';
  @override
  String get enterValue => 'Please enter a value';
  @override
  String get invalidInput =>
      'Invalid input. Use instruction, hex (0xFF), or decimal (0-255)';
  @override
  String valueOutOfRange(int value) =>
      'Value must be between 0 and 255 (got: $value)';
  @override
  String editTitle(String address) => 'EDIT RAM[$address]';
  @override
  String editNote(String hex, int value) =>
      'Now $hex · $value. Type an instruction, a hex value or a decimal '
      'value.';
  @override
  String get inputLabel => 'Instruction / hex / decimal';
  @override
  String get operandNote =>
      'An instruction with an operand stores only its opcode byte; '
      'edit the next address for the operand.';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';

  @override
  String get ioDevices => 'I/O DEVICES';
  @override
  String get ioDevicesNote =>
      'OUT port writes A to a device · IN port reads one into A';
  @override
  String boardButton(String board) => 'Board: $board';
  @override
  String get connecting => 'Connecting…';
  @override
  String get realHardware => 'Real hardware';
  @override
  String mirroredTo(String link) => 'Mirrored to $link';
  @override
  String get mirrorTooltip =>
      'Mirror these devices to an Arduino, ESP32 or Raspberry Pi';
  @override
  String devicePort(int port, String name) => 'port $port · $name';
  @override
  String devicePorts(String ports, String roles) => 'ports $ports · $roles';
  @override
  String get lcdOff => 'display off · send 0x0C to turn it on';
  @override
  String lcdCursor(String hex) => 'cursor $hex';
  @override
  String get writesRight => 'writes go right';
  @override
  String get writesLeft => 'writes go left';
  @override
  String shifted(int by) => 'shifted $by';
  @override
  String matrixSemantics(String rows) => 'LED matrix rows: $rows';
  @override
  String keyTooltip(String key, String hex) => 'Press $key: IN reads $hex';
  @override
  String get noKey => 'no key waiting · IN reads 0';
  @override
  String keyWaiting(String key, String hex) =>
      "waiting: '$key' · IN reads $hex";

  @override
  String get textLcd => 'Text LCD';
  @override
  String get keypad => 'Keypad';
  @override
  String get ledMatrix => 'LED matrix';
  @override
  String get lcdCommandPort => 'LCD command';
  @override
  String get lcdDataPort => 'LCD data';
  @override
  String get matrixRowPort => 'matrix row';
  @override
  String get matrixDataPort => 'matrix data';
  @override
  String get keypadPort => 'keypad';
  @override
  String get displayPort => 'display';
  @override
  String get nothingConnected => 'nothing connected';
  @override
  String get commandRole => 'command';
  @override
  String get dataRole => 'data';
  @override
  String get rowRole => 'row';
  @override
  String hardwarePart(String part) => switch (part) {
    'lcd' => 'HD44780 text LCD',
    'matrix' => 'MAX7219 LED matrix',
    'keypad' => '4x4 keypad',
    'oled' => 'SSD1306 OLED',
    _ => part,
  };

  @override
  String connectingTo(String link) => 'Connecting to $link';
  @override
  String linkError(Object error) => 'Link error: $error';
  @override
  String linkClosed(String link) => '$link closed';
  @override
  String get noAnswer =>
      'No answer from the board. Is the GlassBox firmware on it, '
      'at the right speed?';
  @override
  String protocolMismatch(int board, int ours) =>
      'The board speaks protocol $board; this GlassBox speaks $ours. '
      'Update the firmware.';
  @override
  String connectedNote(String board, List<String> parts) =>
      'Connected: $board with ${parts.isEmpty ? 'no parts' : parts.join(', ')}';
  @override
  String failed(String message) => 'Failed: $message';
  @override
  String disconnectedFrom(String link) => 'Disconnected from $link';
  @override
  String get cannotKeepUp =>
      'The board cannot keep up; resending the state instead';
  @override
  String noAnswerLines(int lines) =>
      'No answer for $lines line(s); resending the state';
  @override
  String sendFailed(Object error) => 'Send failed: $error';
  @override
  String boardRefused(String message) => 'Board refused a line: $message';
  @override
  String boardLog(String message) => 'board: $message';
  @override
  String keyNotOnPad(String key) =>
      "Key '$key' from the board is not on the keypad";

  @override
  String get serialUnavailable =>
      'USB serial is not available on this platform.';
  @override
  String get serialLibraryMissing =>
      'The serial port library could not be loaded.';
  @override
  String get serialNeedsBuild => 'USB serial needs the desktop or web build.';
  @override
  String get chooseSerialPort => 'Choose a serial port';
  @override
  String cannotOpenPort(String name, String? error, bool linux) =>
      'Cannot open $name: ${error ?? 'unknown error'}'
      '${linux ? ' (on Linux, your user may need to be in the dialout group)' : ''}';
  @override
  String writeFailed(String name) => 'Write to $name failed';
  @override
  String get enterAddress => 'Enter the board address';
  @override
  String useWs(String scheme) => 'Use a ws:// address, not $scheme://';
  @override
  String get noHost => 'No host in the address';
  @override
  String noWebSocket(String uri) => 'No WebSocket server at $uri';
  @override
  String get noWebSerial =>
      'This browser has no Web Serial: use Chrome or Edge, or Wi-Fi.';
  @override
  String get usbSerial => 'USB serial';
  @override
  String cannotOpenBrowserPort(Object error) =>
      'Cannot open the port (in use by another program?): $error';
  @override
  String get portClosed => 'The port closed';

  @override
  String get realHardwareTitle => 'REAL HARDWARE';
  @override
  String get hardwareNote =>
      'Mirror the I/O ports to an Arduino, ESP32, Raspberry Pi Pico or '
      'Raspberry Pi running the GlassBox firmware. The screen stays '
      'the reference: after a reset or step-back the board is resent '
      'the whole state.';
  @override
  String get connection => 'Connection';
  @override
  String get wifi => 'Wi-Fi';
  @override
  String get log => 'Log';
  @override
  String get resendState => 'Resend state';
  @override
  String get resendTooltip => 'Reset the board and send the whole state again';
  @override
  String get disconnect => 'Disconnect';
  @override
  String get connect => 'Connect';
  @override
  String get browserPickerHint =>
      'Plug the board in, then Connect: the browser asks which port '
      'to use.';
  @override
  String get portLabel => 'Port';
  @override
  String get noSerialPort => 'No serial port found: plug the board in';
  @override
  String get refresh => 'Refresh';
  @override
  String get refreshTooltip => 'List the serial ports again';
  @override
  String get speed => 'Speed';
  @override
  String baud(int rate, bool firmwareDefault) =>
      '$rate baud${firmwareDefault ? ' (firmware default)' : ''}';
  @override
  String get boardAddress => 'Board address';
  @override
  String get addressHint =>
      'ESP32: the address it prints on its serial port at boot, port 81. '
      'Raspberry Pi: the bridge script\'s address, port 8765.';
  @override
  String get mixedContent =>
      'This page is served over https, so the browser will block a '
      'plain ws:// address. Run GlassBox from http:// or the desktop '
      'app for Wi-Fi.';
  @override
  String connectedTo(String board) => 'Connected to $board';
  @override
  String get noPartsReported => 'no parts reported';
  @override
  String get notConnected => 'Not connected';
  @override
  String get worksWithoutBoard => 'The simulated devices work without a board.';
  @override
  String get inStep => 'in step';
  @override
  String toSend(int lines) => '$lines to send';
  @override
  String get nothingToChoose => 'Nothing to choose';
}

class _Fr implements BoardStrings {
  const _Fr();

  @override
  String get programCounter => 'COMPTEUR DE PROGRAMME';
  @override
  String get memoryAddress => 'ADRESSE MÉMOIRE';
  @override
  String get instruction => 'INSTRUCTION';
  @override
  String get stackPointer => 'POINTEUR DE PILE';
  @override
  String get registerA => 'REGISTRE A';
  @override
  String get registerB => 'REGISTRE B';
  @override
  String get alu => 'UAL · Σ';
  @override
  String get outputRegister => 'REGISTRE DE SORTIE';
  @override
  String get ioPort => 'PORT E/S';
  @override
  String get flags => 'INDICATEURS';
  @override
  String bitsWide(int bits) => '$bits bits';
  @override
  String get ramPortIdle => 'port';
  @override
  String get accumulator => 'accumulateur';
  @override
  String get operand => 'opérande';
  @override
  String get operandIndex => 'opérande · index';
  @override
  String port(int port) => 'port $port';
  @override
  String get stopped => 'arrêté';
  @override
  String next(String instruction) => 'suivante : $instruction';
  @override
  String selectsRam(String address, String? symbol) =>
      'sélectionne RAM[$address]${symbol == null ? '' : ' · $symbol'}';
  @override
  String get irEmpty => 'vide avant la 1re lecture';
  @override
  String irExtended(String instruction, String? operandAddress) =>
      '$instruction'
      '${operandAddress == null ? '' : ' · opérande en $operandAddress'}';
  @override
  String irClassic(String instruction, int opcode, int operand) =>
      '$instruction · opcode $opcode · opérande $operand';
  @override
  String get stackEmpty => 'vide · croît vers le bas';
  @override
  String stackBytes(int bytes) =>
      '$bytes octet${bytes == 1 ? '' : 's'} sur la pile';
  @override
  String aluNote(String operation, int value, bool carry) =>
      '$operation = $value${carry ? ' · retenue sortante' : ''}';
  @override
  String outputNote(String value) => '$value · pilote l’afficheur';
  @override
  String portToBus(String name, String hex) => '$name → bus : $hex';
  @override
  String portNote(int port, String name) => 'port $port · $name';
  @override
  String get busIdle => 'rien ne pilote le bus à cette étape';
  @override
  String busWho(String source, List<String> readers) =>
      '$source pilote'
      '${readers.isEmpty ? '' : ' · ${readers.join(', ')} ${readers.length == 1 ? 'lit' : 'lisent'}'}';
  @override
  String get flagsLatchedWire => 'FI · indicateurs verrouillés depuis l’UAL';
  @override
  String get flagsInWire => 'FI · indicateurs ← résultat de l’UAL';
  @override
  String get carry => 'retenue';
  @override
  String get zero => 'zéro';
  @override
  String get kept => 'conservés';
  @override
  String get latched => 'VERROUILLÉS';
  @override
  String flagsDecide(String jumps) => '→ microcode : décide $jumps';
  @override
  String get display => 'AFFICHEUR';
  @override
  String valueCount(int count) => '$count valeur${count == 1 ? '' : 's'}';
  @override
  String displaySemantics(int value) => 'Afficheur : $value';
  @override
  String get displayEmpty => 'rien en sortie pour l’instant\nOUT copie A ici';
  @override
  String get asText => 'en texte';
  @override
  String get newestFirst => 'plus récente d’abord';

  @override
  String get drivesBus => 'PILOTE LE BUS ▸';
  @override
  String get readsBus => '◂ LIT LE BUS';
  @override
  String get counts => 'COMPTE';
  @override
  String get close => 'Fermer';

  @override
  String get ram => 'RAM';
  @override
  String ramSummary(int bytes, int addressBits) =>
      '$bytes octets · adresses $addressBits bits · clic pour modifier';
  @override
  String get goToPc => 'Aller au PC';
  @override
  String get goToSp => 'Aller au SP';
  @override
  String get enterValue => 'Saisir une valeur';
  @override
  String get invalidInput =>
      'Saisie invalide. Utiliser une instruction, de l’hexa (0xFF) ou du '
      'décimal (0-255)';
  @override
  String valueOutOfRange(int value) =>
      'La valeur doit être entre 0 et 255 (reçu : $value)';
  @override
  String editTitle(String address) => 'MODIFIER RAM[$address]';
  @override
  String editNote(String hex, int value) =>
      'Actuellement $hex · $value. Saisir une instruction, une valeur hexa '
      'ou une valeur décimale.';
  @override
  String get inputLabel => 'Instruction / hexa / décimal';
  @override
  String get operandNote =>
      'Une instruction avec opérande ne stocke que son octet d’opcode ; '
      'modifier l’adresse suivante pour l’opérande.';
  @override
  String get cancel => 'Annuler';
  @override
  String get save => 'Enregistrer';

  @override
  String get ioDevices => 'PÉRIPHÉRIQUES E/S';
  @override
  String get ioDevicesNote =>
      'OUT port écrit A vers un périphérique · IN port en lit un dans A';
  @override
  String boardButton(String board) => 'Carte : $board';
  @override
  String get connecting => 'Connexion…';
  @override
  String get realHardware => 'Matériel réel';
  @override
  String mirroredTo(String link) => 'Reproduit sur $link';
  @override
  String get mirrorTooltip =>
      'Reproduire ces périphériques sur un Arduino, un ESP32 ou un '
      'Raspberry Pi';
  @override
  String devicePort(int port, String name) => 'port $port · $name';
  @override
  String devicePorts(String ports, String roles) => 'ports $ports · $roles';
  @override
  String get lcdOff => 'affichage éteint · envoyer 0x0C pour l’allumer';
  @override
  String lcdCursor(String hex) => 'curseur $hex';
  @override
  String get writesRight => 'écriture vers la droite';
  @override
  String get writesLeft => 'écriture vers la gauche';
  @override
  String shifted(int by) => 'décalé de $by';
  @override
  String matrixSemantics(String rows) => 'Lignes de la matrice de LED : $rows';
  @override
  String keyTooltip(String key, String hex) => 'Appuyer sur $key : IN lit $hex';
  @override
  String get noKey => 'aucune touche en attente · IN lit 0';
  @override
  String keyWaiting(String key, String hex) =>
      "en attente : '$key' · IN lit $hex";

  @override
  String get textLcd => 'LCD texte';
  @override
  String get keypad => 'Clavier';
  @override
  String get ledMatrix => 'Matrice de LED';
  @override
  String get lcdCommandPort => 'commande LCD';
  @override
  String get lcdDataPort => 'données LCD';
  @override
  String get matrixRowPort => 'ligne de la matrice';
  @override
  String get matrixDataPort => 'données de la matrice';
  @override
  String get keypadPort => 'clavier';
  @override
  String get displayPort => 'afficheur';
  @override
  String get nothingConnected => 'rien de connecté';
  @override
  String get commandRole => 'commande';
  @override
  String get dataRole => 'données';
  @override
  String get rowRole => 'ligne';
  @override
  String hardwarePart(String part) => switch (part) {
    'lcd' => 'LCD texte HD44780',
    'matrix' => 'matrice de LED MAX7219',
    'keypad' => 'clavier 4x4',
    'oled' => 'OLED SSD1306',
    _ => part,
  };

  @override
  String connectingTo(String link) => 'Connexion à $link';
  @override
  String linkError(Object error) => 'Erreur de liaison : $error';
  @override
  String linkClosed(String link) => '$link fermé';
  @override
  String get noAnswer =>
      'Pas de réponse de la carte. Le firmware GlassBox y est-il installé, '
      'à la bonne vitesse ?';
  @override
  String protocolMismatch(int board, int ours) =>
      'La carte parle le protocole $board ; ce GlassBox parle le $ours. '
      'Mettre à jour le firmware.';
  @override
  String connectedNote(String board, List<String> parts) =>
      'Connecté : $board '
      '${parts.isEmpty ? 'sans composants' : 'avec ${parts.join(', ')}'}';
  @override
  String failed(String message) => 'Échec : $message';
  @override
  String disconnectedFrom(String link) => 'Déconnecté de $link';
  @override
  String get cannotKeepUp =>
      'La carte ne suit pas ; renvoi de l’état à la place';
  @override
  String noAnswerLines(int lines) =>
      'Pas de réponse pour $lines ligne(s) ; renvoi de l’état';
  @override
  String sendFailed(Object error) => 'Échec de l’envoi : $error';
  @override
  String boardRefused(String message) =>
      'La carte a refusé une ligne : $message';
  @override
  String boardLog(String message) => 'carte : $message';
  @override
  String keyNotOnPad(String key) =>
      "La touche '$key' de la carte n’est pas sur le clavier";

  @override
  String get serialUnavailable =>
      'L’USB série n’est pas disponible sur cette plateforme.';
  @override
  String get serialLibraryMissing =>
      'La bibliothèque de port série n’a pas pu être chargée.';
  @override
  String get serialNeedsBuild =>
      'L’USB série nécessite la version bureau ou web.';
  @override
  String get chooseSerialPort => 'Choisir un port série';
  @override
  String cannotOpenPort(String name, String? error, bool linux) =>
      'Impossible d’ouvrir $name : ${error ?? 'erreur inconnue'}'
      '${linux ? ' (sous Linux, l’utilisateur doit peut-être appartenir au groupe dialout)' : ''}';
  @override
  String writeFailed(String name) => 'Échec de l’écriture sur $name';
  @override
  String get enterAddress => 'Saisir l’adresse de la carte';
  @override
  String useWs(String scheme) => 'Utiliser une adresse ws://, pas $scheme://';
  @override
  String get noHost => 'Pas d’hôte dans l’adresse';
  @override
  String noWebSocket(String uri) => 'Aucun serveur WebSocket à $uri';
  @override
  String get noWebSerial =>
      'Ce navigateur n’a pas Web Serial : utiliser Chrome ou Edge, ou '
      'le Wi-Fi.';
  @override
  String get usbSerial => 'USB série';
  @override
  String cannotOpenBrowserPort(Object error) =>
      'Impossible d’ouvrir le port (utilisé par un autre programme ?)'
      ' : $error';
  @override
  String get portClosed => 'Le port s’est fermé';

  @override
  String get realHardwareTitle => 'MATÉRIEL RÉEL';
  @override
  String get hardwareNote =>
      'Reproduire les ports E/S sur un Arduino, un ESP32, un Raspberry Pi '
      'Pico ou un Raspberry Pi équipé du firmware GlassBox. L’écran reste '
      'la référence : après une réinitialisation ou un retour en '
      'arrière, tout l’état est renvoyé à la carte.';
  @override
  String get connection => 'Connexion';
  @override
  String get wifi => 'Wi-Fi';
  @override
  String get log => 'Journal';
  @override
  String get resendState => 'Renvoyer l’état';
  @override
  String get resendTooltip => 'Réinitialiser la carte et renvoyer tout l’état';
  @override
  String get disconnect => 'Déconnecter';
  @override
  String get connect => 'Connecter';
  @override
  String get browserPickerHint =>
      'Brancher la carte, puis Connecter : le navigateur demande quel '
      'port utiliser.';
  @override
  String get portLabel => 'Port';
  @override
  String get noSerialPort => 'Aucun port série trouvé : brancher la carte';
  @override
  String get refresh => 'Actualiser';
  @override
  String get refreshTooltip => 'Lister à nouveau les ports série';
  @override
  String get speed => 'Vitesse';
  @override
  String baud(int rate, bool firmwareDefault) =>
      '$rate bauds${firmwareDefault ? ' (défaut du firmware)' : ''}';
  @override
  String get boardAddress => 'Adresse de la carte';
  @override
  String get addressHint =>
      'ESP32 : l’adresse qu’il affiche sur son port série au démarrage, '
      'port 81. Raspberry Pi : l’adresse du script passerelle, '
      'port 8765.';
  @override
  String get mixedContent =>
      'Cette page est servie en https, le navigateur bloquera donc une '
      'adresse ws:// simple. Pour le Wi-Fi, lancer GlassBox depuis http:// '
      'ou l’application de bureau.';
  @override
  String connectedTo(String board) => 'Connecté à $board';
  @override
  String get noPartsReported => 'aucun composant signalé';
  @override
  String get notConnected => 'Non connecté';
  @override
  String get worksWithoutBoard =>
      'Les périphériques simulés fonctionnent sans carte.';
  @override
  String get inStep => 'synchronisé';
  @override
  String toSend(int lines) => '$lines à envoyer';
  @override
  String get nothingToChoose => 'Rien à choisir';
}

class _De implements BoardStrings {
  const _De();

  @override
  String get programCounter => 'PROGRAMMZÄHLER';
  @override
  String get memoryAddress => 'SPEICHERADRESSE';
  @override
  String get instruction => 'BEFEHL';
  @override
  String get stackPointer => 'STAPELZEIGER';
  @override
  String get registerA => 'REGISTER A';
  @override
  String get registerB => 'REGISTER B';
  @override
  String get alu => 'ALU · Σ';
  @override
  String get outputRegister => 'AUSGABEREGISTER';
  @override
  String get ioPort => 'E/A-PORT';
  @override
  String get flags => 'FLAGS';
  @override
  String bitsWide(int bits) => '$bits Bit';
  @override
  String get ramPortIdle => 'Port';
  @override
  String get accumulator => 'Akkumulator';
  @override
  String get operand => 'Operand';
  @override
  String get operandIndex => 'Operand · Index';
  @override
  String port(int port) => 'Port $port';
  @override
  String get stopped => 'angehalten';
  @override
  String next(String instruction) => 'nächster: $instruction';
  @override
  String selectsRam(String address, String? symbol) =>
      'wählt RAM[$address]${symbol == null ? '' : ' · $symbol'}';
  @override
  String get irEmpty => 'leer bis zum ersten Holen';
  @override
  String irExtended(String instruction, String? operandAddress) =>
      '$instruction'
      '${operandAddress == null ? '' : ' · Operand bei $operandAddress'}';
  @override
  String irClassic(String instruction, int opcode, int operand) =>
      '$instruction · Opcode $opcode · Operand $operand';
  @override
  String get stackEmpty => 'leer · wächst nach unten';
  @override
  String stackBytes(int bytes) => '$bytes Byte auf dem Stapel';
  @override
  String aluNote(String operation, int value, bool carry) =>
      '$operation = $value${carry ? ' · Übertrag' : ''}';
  @override
  String outputNote(String value) => '$value · treibt die Anzeige';
  @override
  String portToBus(String name, String hex) => '$name → Bus: $hex';
  @override
  String portNote(int port, String name) => 'Port $port · $name';
  @override
  String get busIdle => 'nichts treibt den Bus in diesem Schritt';
  @override
  String busWho(String source, List<String> readers) =>
      '$source treibt'
      '${readers.isEmpty ? '' : ' · ${readers.join(', ')} ${readers.length == 1 ? 'liest' : 'lesen'}'}';
  @override
  String get flagsLatchedWire => 'FI · Flags aus der ALU übernommen';
  @override
  String get flagsInWire => 'FI · Flags ein, aus dem ALU-Ergebnis';
  @override
  String get carry => 'Übertrag';
  @override
  String get zero => 'Null';
  @override
  String get kept => 'gehalten';
  @override
  String get latched => 'ÜBERNOMMEN';
  @override
  String flagsDecide(String jumps) => '→ Mikrocode: entscheidet $jumps';
  @override
  String get display => 'ANZEIGE';
  @override
  String valueCount(int count) => '$count ${count == 1 ? 'Wert' : 'Werte'}';
  @override
  String displaySemantics(int value) => 'Anzeige: $value';
  @override
  String get displayEmpty => 'noch keine Ausgabe\nOUT kopiert A hierher';
  @override
  String get asText => 'als Text';
  @override
  String get newestFirst => 'neueste zuerst';

  @override
  String get drivesBus => 'TREIBT BUS ▸';
  @override
  String get readsBus => '◂ LIEST BUS';
  @override
  String get counts => 'ZÄHLT';
  @override
  String get close => 'Schließen';

  @override
  String get ram => 'RAM';
  @override
  String ramSummary(int bytes, int addressBits) =>
      '$bytes Byte · $addressBits-Bit-Adressen · zum Bearbeiten tippen';
  @override
  String get goToPc => 'Zum PC';
  @override
  String get goToSp => 'Zum SP';
  @override
  String get enterValue => 'Bitte einen Wert eingeben';
  @override
  String get invalidInput =>
      'Ungültige Eingabe. Befehl, Hex (0xFF) oder Dezimal (0-255) verwenden';
  @override
  String valueOutOfRange(int value) =>
      'Wert muss zwischen 0 und 255 liegen (erhalten: $value)';
  @override
  String editTitle(String address) => 'RAM[$address] BEARBEITEN';
  @override
  String editNote(String hex, int value) =>
      'Jetzt $hex · $value. Einen Befehl, einen Hex- oder einen Dezimalwert '
      'eingeben.';
  @override
  String get inputLabel => 'Befehl / Hex / Dezimal';
  @override
  String get operandNote =>
      'Ein Befehl mit Operand speichert nur sein Opcode-Byte; den Operanden '
      'an der nächsten Adresse bearbeiten.';
  @override
  String get cancel => 'Abbrechen';
  @override
  String get save => 'Speichern';

  @override
  String get ioDevices => 'E/A-GERÄTE';
  @override
  String get ioDevicesNote =>
      'OUT port schreibt A in ein Gerät · IN port liest eines in A';
  @override
  String boardButton(String board) => 'Board: $board';
  @override
  String get connecting => 'Verbindet…';
  @override
  String get realHardware => 'Echte Hardware';
  @override
  String mirroredTo(String link) => 'Gespiegelt auf $link';
  @override
  String get mirrorTooltip =>
      'Diese Geräte auf einen Arduino, ESP32 oder Raspberry Pi spiegeln';
  @override
  String devicePort(int port, String name) => 'Port $port · $name';
  @override
  String devicePorts(String ports, String roles) => 'Ports $ports · $roles';
  @override
  String get lcdOff => 'Anzeige aus · 0x0C senden zum Einschalten';
  @override
  String lcdCursor(String hex) => 'Cursor $hex';
  @override
  String get writesRight => 'Schreiben nach rechts';
  @override
  String get writesLeft => 'Schreiben nach links';
  @override
  String shifted(int by) => 'verschoben um $by';
  @override
  String matrixSemantics(String rows) => 'LED-Matrix-Zeilen: $rows';
  @override
  String keyTooltip(String key, String hex) => '$key drücken: IN liest $hex';
  @override
  String get noKey => 'keine Taste wartet · IN liest 0';
  @override
  String keyWaiting(String key, String hex) => "wartet: '$key' · IN liest $hex";

  @override
  String get textLcd => 'Text-LCD';
  @override
  String get keypad => 'Tastenfeld';
  @override
  String get ledMatrix => 'LED-Matrix';
  @override
  String get lcdCommandPort => 'LCD-Befehl';
  @override
  String get lcdDataPort => 'LCD-Daten';
  @override
  String get matrixRowPort => 'Matrixzeile';
  @override
  String get matrixDataPort => 'Matrixdaten';
  @override
  String get keypadPort => 'Tastenfeld';
  @override
  String get displayPort => 'Anzeige';
  @override
  String get nothingConnected => 'nichts angeschlossen';
  @override
  String get commandRole => 'Befehl';
  @override
  String get dataRole => 'Daten';
  @override
  String get rowRole => 'Zeile';
  @override
  String hardwarePart(String part) => switch (part) {
    'lcd' => 'HD44780-Text-LCD',
    'matrix' => 'MAX7219-LED-Matrix',
    'keypad' => '4x4-Tastenfeld',
    'oled' => 'SSD1306-OLED',
    _ => part,
  };

  @override
  String connectingTo(String link) => 'Verbinde mit $link';
  @override
  String linkError(Object error) => 'Verbindungsfehler: $error';
  @override
  String linkClosed(String link) => '$link geschlossen';
  @override
  String get noAnswer =>
      'Keine Antwort vom Board. Ist die GlassBox-Firmware darauf, mit der '
      'richtigen Geschwindigkeit?';
  @override
  String protocolMismatch(int board, int ours) =>
      'Das Board spricht Protokoll $board, dieses GlassBox spricht $ours. '
      'Firmware aktualisieren.';
  @override
  String connectedNote(String board, List<String> parts) =>
      'Verbunden: $board '
      '${parts.isEmpty ? 'ohne Bauteile' : 'mit ${parts.join(', ')}'}';
  @override
  String failed(String message) => 'Fehlgeschlagen: $message';
  @override
  String disconnectedFrom(String link) => 'Getrennt von $link';
  @override
  String get cannotKeepUp =>
      'Das Board kommt nicht mit; stattdessen wird der Zustand neu gesendet';
  @override
  String noAnswerLines(int lines) =>
      'Keine Antwort auf $lines Zeile(n); Zustand wird neu gesendet';
  @override
  String sendFailed(Object error) => 'Senden fehlgeschlagen: $error';
  @override
  String boardRefused(String message) =>
      'Board hat eine Zeile abgelehnt: $message';
  @override
  String boardLog(String message) => 'Board: $message';
  @override
  String keyNotOnPad(String key) =>
      "Taste '$key' vom Board ist nicht auf dem Tastenfeld";

  @override
  String get serialUnavailable =>
      'USB-Seriell ist auf dieser Plattform nicht verfügbar.';
  @override
  String get serialLibraryMissing =>
      'Die Bibliothek für serielle Ports konnte nicht geladen werden.';
  @override
  String get serialNeedsBuild =>
      'USB-Seriell erfordert die Desktop- oder Web-Version.';
  @override
  String get chooseSerialPort => 'Seriellen Port wählen';
  @override
  String cannotOpenPort(String name, String? error, bool linux) =>
      '$name kann nicht geöffnet werden: ${error ?? 'unbekannter Fehler'}'
      '${linux ? ' (unter Linux muss der Benutzer eventuell in der Gruppe dialout sein)' : ''}';
  @override
  String writeFailed(String name) => 'Schreiben auf $name fehlgeschlagen';
  @override
  String get enterAddress => 'Board-Adresse eingeben';
  @override
  String useWs(String scheme) =>
      'Eine ws://-Adresse verwenden, nicht $scheme://';
  @override
  String get noHost => 'Kein Host in der Adresse';
  @override
  String noWebSocket(String uri) => 'Kein WebSocket-Server unter $uri';
  @override
  String get noWebSerial =>
      'Dieser Browser hat kein Web Serial: Chrome oder Edge verwenden, oder '
      'WLAN.';
  @override
  String get usbSerial => 'USB-Seriell';
  @override
  String cannotOpenBrowserPort(Object error) =>
      'Port kann nicht geöffnet werden (von einem anderen Programm belegt?): '
      '$error';
  @override
  String get portClosed => 'Der Port wurde geschlossen';

  @override
  String get realHardwareTitle => 'ECHTE HARDWARE';
  @override
  String get hardwareNote =>
      'Die E/A-Ports auf einen Arduino, ESP32, Raspberry Pi Pico oder '
      'Raspberry Pi mit der GlassBox-Firmware spiegeln. Der Bildschirm '
      'bleibt maßgeblich: Nach einem Zurücksetzen oder Schritt zurück '
      'erhält das Board den gesamten Zustand neu.';
  @override
  String get connection => 'Verbindung';
  @override
  String get wifi => 'WLAN';
  @override
  String get log => 'Protokoll';
  @override
  String get resendState => 'Zustand neu senden';
  @override
  String get resendTooltip =>
      'Board zurücksetzen und den gesamten Zustand erneut senden';
  @override
  String get disconnect => 'Trennen';
  @override
  String get connect => 'Verbinden';
  @override
  String get browserPickerHint =>
      'Board anschließen, dann Verbinden: Der Browser fragt, welcher Port '
      'verwendet wird.';
  @override
  String get portLabel => 'Port';
  @override
  String get noSerialPort => 'Kein serieller Port gefunden: Board anschließen';
  @override
  String get refresh => 'Aktualisieren';
  @override
  String get refreshTooltip => 'Serielle Ports neu auflisten';
  @override
  String get speed => 'Geschwindigkeit';
  @override
  String baud(int rate, bool firmwareDefault) =>
      '$rate Baud${firmwareDefault ? ' (Firmware-Standard)' : ''}';
  @override
  String get boardAddress => 'Board-Adresse';
  @override
  String get addressHint =>
      'ESP32: die Adresse, die er beim Start auf seinem seriellen Port '
      'ausgibt, Port 81. Raspberry Pi: die Adresse des Bridge-Skripts, '
      'Port 8765.';
  @override
  String get mixedContent =>
      'Diese Seite wird über https ausgeliefert, daher blockiert der Browser '
      'eine einfache ws://-Adresse. Für WLAN GlassBox über http:// oder die '
      'Desktop-App starten.';
  @override
  String connectedTo(String board) => 'Verbunden mit $board';
  @override
  String get noPartsReported => 'keine Bauteile gemeldet';
  @override
  String get notConnected => 'Nicht verbunden';
  @override
  String get worksWithoutBoard =>
      'Die simulierten Geräte funktionieren ohne Board.';
  @override
  String get inStep => 'synchron';
  @override
  String toSend(int lines) => '$lines zu senden';
  @override
  String get nothingToChoose => 'Keine Auswahl';
}
