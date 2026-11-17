import 'l10n.dart';

/// Text of the app frame (top bar, narration strip, About dialog, small
/// window screen) and of the step narration, CPU modes and microcode panel.
abstract class AppStrings {
  // Window too small.
  String get windowTooSmallTitle; // 'WINDOW TOO SMALL'
  String get windowTooSmallBody;
  String windowSizes(int needW, int needH, int nowW, int nowH);

  // CPU modes.
  String get classicLabel; // 'Classic'
  String get extendedLabel; // 'Extended'
  String get classicDescription;
  String get extendedDescription;
  String get bytesUnit; // 'B', as in '16 B'

  // Top bar.
  String get tagline; // 'every signal visible'
  String modeTooltip(String classic, String extended);
  String get machine; // semantic label of the CPU mode switch
  String get view; // semantic label of the view switch
  String get language; // semantic label of the language switch
  String get simple;
  String get detailed;
  String get aboutTooltip;
  String get stepBackTooltip;
  String get step; // first part of the two step buttons
  String get stepCycle; // 'cycle'
  String get stepCycleTooltip;
  String get stepInstruction; // 'instruction'
  String get stepInstructionTooltip;
  String get run;
  String get pause;
  String get runTooltip;
  String get runToCursor;
  String get runToCursorTooltip;
  String get reset;
  String get resetTooltip;
  String get halted; // clock LED tooltip when halted
  String clockState(bool high); // 'Clock high'
  String get clock; // label before the speed slider
  String get decimalSeparator;

  // Narration strip.
  String get lastStep; // semantic label
  String get signals;
  String get haltedNext;
  String nextFetch(String instruction, String address, int? line);
  String nextStep(int step, String purpose);

  // Step narration (core/step_info.dart).
  String get bus; // the word in 'A = 0x09 → bus → OUT'
  String get ready;
  String nextFetchesAt(String address);
  String get irOperand; // source label 'IR operand'
  String get ioNode; // bus node label 'I/O'
  String flags(int carry, int zero); // 'flags C=0 Z=1'
  String get clockStopped;
  String get nothingThisCycle;
  String port(int port, String name); // 'port 2 (LCD data)'
  String get fetchAddress; // purpose of T0
  String get fetchLoad; // purpose of T1

  // Microcode panel and signal groups.
  String get fetch; // 'MICROCODE · fetch'
  String microcodeTitle(String name);
  String get unused;
  String get groupDrive;
  String get groupRead;
  String get groupCounters;
  String get groupAlu;
  String get groupControl;
  String get noteNothing;
  String get noteDevice;
  String get noteFlags;
  String get noteHalt;

  // About dialog.
  String get aboutTitle;
  String get aboutIntro;

  /// Credits sentence with the placeholders `{muaz}` and `{eater}` where
  /// the two links go.
  String get aboutCredits;
  String get licenceTitle;
  String get licenceText;
  String get quote;
}

/// The current language's app text.
AppStrings get tApp => L10n.pick(const _En(), const _Fr(), const _De());

class _En implements AppStrings {
  const _En();

  @override
  String get windowTooSmallTitle => 'WINDOW TOO SMALL';
  @override
  String get windowTooSmallBody =>
      'GlassBox CPU shows the whole board at once. Make the '
      'window larger or switch to full screen.';
  @override
  String windowSizes(int needW, int needH, int nowW, int nowH) =>
      'Needs ${needW}x$needH px · now ${nowW}x$nowH px';

  @override
  String get classicLabel => 'Classic';
  @override
  String get extendedLabel => 'Extended';
  @override
  String get classicDescription =>
      '16 bytes of RAM, 4-bit operands, 11 instructions';
  @override
  String get extendedDescription =>
      '256 bytes of RAM, 8-bit operands, stack, I/O ports, 29 instructions';
  @override
  String get bytesUnit => 'B';

  @override
  String get tagline => 'every signal visible';
  @override
  String modeTooltip(String classic, String extended) =>
      'Classic: $classic\nExtended: $extended\nSwitching clears RAM.';
  @override
  String get machine => 'Machine';
  @override
  String get view => 'View';
  @override
  String get language => 'Language';
  @override
  String get simple => 'Simple';
  @override
  String get detailed => 'Detailed';
  @override
  String get aboutTooltip => 'About GlassBox CPU';
  @override
  String get stepBackTooltip => 'Step back: undo the last step';
  @override
  String get step => 'Step';
  @override
  String get stepCycle => 'cycle';
  @override
  String get stepCycleTooltip => 'One clock cycle (micro-step)';
  @override
  String get stepInstruction => 'instruction';
  @override
  String get stepInstructionTooltip =>
      'Run the rest of the current instruction';
  @override
  String get run => 'Run';
  @override
  String get pause => 'Pause';
  @override
  String get runTooltip => 'Run until a breakpoint or HLT';
  @override
  String get runToCursor => 'Run to cursor';
  @override
  String get runToCursorTooltip =>
      'Run until the instruction on the editor cursor line';
  @override
  String get reset => 'Reset';
  @override
  String get resetTooltip => 'Restart the loaded program';
  @override
  String get halted => 'Halted';
  @override
  String clockState(bool high) => 'Clock ${high ? 'high' : 'low'}';
  @override
  String get clock => 'Clock';
  @override
  String get decimalSeparator => '.';

  @override
  String get lastStep => 'Last step';
  @override
  String get signals => 'signals';
  @override
  String get haltedNext => 'Halted. Reset to run the program again.';
  @override
  String nextFetch(String instruction, String address, int? line) =>
      'Next: fetch $instruction at $address'
      '${line == null ? '' : ' · line $line'}';
  @override
  String nextStep(int step, String purpose) => 'Next: T$step of $purpose';

  @override
  String get bus => 'bus';
  @override
  String get ready => 'ready';
  @override
  String nextFetchesAt(String address) =>
      'next step fetches the instruction at $address';
  @override
  String get irOperand => 'IR operand';
  @override
  String get ioNode => 'I/O';
  @override
  String flags(int carry, int zero) => 'flags C=$carry Z=$zero';
  @override
  String get clockStopped => 'clock stopped';
  @override
  String get nothingThisCycle => 'nothing to do this cycle';
  @override
  String port(int port, String name) => 'port $port ($name)';
  @override
  String get fetchAddress => 'fetch: address of next instruction';
  @override
  String get fetchLoad => 'fetch: load instruction, advance PC';

  @override
  String get fetch => 'fetch';
  @override
  String microcodeTitle(String name) => 'MICROCODE · $name';
  @override
  String get unused => 'unused';
  @override
  String get groupDrive => 'Drive bus';
  @override
  String get groupRead => 'Read bus';
  @override
  String get groupCounters => 'Counters';
  @override
  String get groupAlu => 'ALU';
  @override
  String get groupControl => 'Control';
  @override
  String get noteNothing => 'nothing';
  @override
  String get noteDevice => 'device';
  @override
  String get noteFlags => 'flags';
  @override
  String get noteHalt => 'halt';

  @override
  String get aboutTitle => 'ABOUT GLASSBOX CPU';
  @override
  String get aboutIntro =>
      'A visual simulator of an 8-bit breadboard CPU: every '
      'step shows who drives the bus, who reads it, and why.';
  @override
  String get aboutCredits =>
      "Based on the 8-bit CPU Simulator by {muaz}, inspired by {eater}'s "
      '8-bit breadboard computer.';
  @override
  String get licenceTitle => 'Licence';
  @override
  String get licenceText =>
      'Released under the GNU GPL v3. The original simulator code '
      'remains under the MIT licence (see LICENSE and LICENSE-MIT).';
  @override
  String get quote =>
      '"Every complex system is just simple parts working together."';
}

class _Fr implements AppStrings {
  const _Fr();

  @override
  String get windowTooSmallTitle => 'FENÊTRE TROP PETITE';
  @override
  String get windowTooSmallBody =>
      'GlassBox CPU affiche toute la carte d’un coup. Agrandir la '
      'fenêtre ou passer en plein écran.';
  @override
  String windowSizes(int needW, int needH, int nowW, int nowH) =>
      'Requiert ${needW}x$needH px · actuellement ${nowW}x$nowH px';

  @override
  String get classicLabel => 'Classique';
  @override
  String get extendedLabel => 'Étendu';
  @override
  String get classicDescription =>
      '16 octets de RAM, opérandes de 4 bits, 11 instructions';
  @override
  String get extendedDescription =>
      '256 octets de RAM, opérandes de 8 bits, pile, ports d’E/S, '
      '29 instructions';
  @override
  String get bytesUnit => 'o';

  @override
  String get tagline => 'chaque signal visible';
  @override
  String modeTooltip(String classic, String extended) =>
      'Classique : $classic\nÉtendu : $extended\n'
      'Changer de mode efface la RAM.';
  @override
  String get machine => 'Machine';
  @override
  String get view => 'Vue';
  @override
  String get language => 'Langue';
  @override
  String get simple => 'Simple';
  @override
  String get detailed => 'Détaillé';
  @override
  String get aboutTooltip => 'À propos de GlassBox CPU';
  @override
  String get stepBackTooltip => 'Pas en arrière : annuler le dernier pas';
  @override
  String get step => 'Pas';
  @override
  String get stepCycle => 'cycle';
  @override
  String get stepCycleTooltip => 'Un cycle d’horloge (micro-étape)';
  @override
  String get stepInstruction => 'instruction';
  @override
  String get stepInstructionTooltip =>
      'Exécuter le reste de l’instruction en cours';
  @override
  String get run => 'Exécuter';
  @override
  String get pause => 'Pause';
  @override
  String get runTooltip => 'Exécuter jusqu’à un point d’arrêt ou HLT';
  @override
  String get runToCursor => 'Jusqu’au curseur';
  @override
  String get runToCursorTooltip =>
      'Exécuter jusqu’à l’instruction de la ligne du curseur';
  @override
  String get reset => 'Réinitialiser';
  @override
  String get resetTooltip => 'Relancer le programme chargé';
  @override
  String get halted => 'Arrêté';
  @override
  String clockState(bool high) => 'Horloge ${high ? 'haute' : 'basse'}';
  @override
  String get clock => 'Horloge';
  @override
  String get decimalSeparator => ',';

  @override
  String get lastStep => 'Dernière étape';
  @override
  String get signals => 'signaux';
  @override
  String get haltedNext =>
      'Arrêté. Réinitialiser pour exécuter à nouveau le programme.';
  @override
  String nextFetch(String instruction, String address, int? line) =>
      'Suivant : lecture de $instruction à l’adresse $address'
      '${line == null ? '' : ' · ligne $line'}';
  @override
  String nextStep(int step, String purpose) => 'Suivant : T$step de $purpose';

  @override
  String get bus => 'bus';
  @override
  String get ready => 'prêt';
  @override
  String nextFetchesAt(String address) =>
      'l’étape suivante lit l’instruction à l’adresse $address';
  @override
  String get irOperand => 'opérande de IR';
  @override
  String get ioNode => 'E/S';
  @override
  String flags(int carry, int zero) => 'indicateurs C=$carry Z=$zero';
  @override
  String get clockStopped => 'horloge arrêtée';
  @override
  String get nothingThisCycle => 'rien à faire pendant ce cycle';
  @override
  String port(int port, String name) => 'port $port ($name)';
  @override
  String get fetchAddress => 'lecture : adresse de l’instruction suivante';
  @override
  String get fetchLoad => 'lecture : charger l’instruction, avancer le PC';

  @override
  String get fetch => 'lecture';
  @override
  String microcodeTitle(String name) => 'MICROCODE · $name';
  @override
  String get unused => 'inutilisé';
  @override
  String get groupDrive => 'Pilotage bus';
  @override
  String get groupRead => 'Lecture bus';
  @override
  String get groupCounters => 'Compteurs';
  @override
  String get groupAlu => 'ALU';
  @override
  String get groupControl => 'Contrôle';
  @override
  String get noteNothing => 'rien';
  @override
  String get noteDevice => 'périphérique';
  @override
  String get noteFlags => 'indicateurs';
  @override
  String get noteHalt => 'arrêt';

  @override
  String get aboutTitle => 'À PROPOS DE GLASSBOX CPU';
  @override
  String get aboutIntro =>
      'Un simulateur visuel d’un CPU 8 bits sur plaque d’essai : '
      'chaque étape montre qui pilote le bus, qui le lit, et pourquoi.';
  @override
  String get aboutCredits =>
      'Basé sur le 8-bit CPU Simulator de {muaz}, inspiré de '
      'l’ordinateur 8 bits sur plaque d’essai de {eater}.';
  @override
  String get licenceTitle => 'Licence';
  @override
  String get licenceText =>
      'Publié sous licence GNU GPL v3. Le code du simulateur d’origine '
      'reste sous licence MIT (voir LICENSE et LICENSE-MIT).';
  @override
  String get quote =>
      '« Tout système complexe n’est que des parties simples qui '
      'travaillent ensemble. »';
}

class _De implements AppStrings {
  const _De();

  @override
  String get windowTooSmallTitle => 'FENSTER ZU KLEIN';
  @override
  String get windowTooSmallBody =>
      'GlassBox CPU zeigt die ganze Platine auf einmal. Das Fenster '
      'vergrößern oder in den Vollbildmodus wechseln.';
  @override
  String windowSizes(int needW, int needH, int nowW, int nowH) =>
      'Benötigt ${needW}x$needH px · aktuell ${nowW}x$nowH px';

  @override
  String get classicLabel => 'Klassisch';
  @override
  String get extendedLabel => 'Erweitert';
  @override
  String get classicDescription => '16 Byte RAM, 4-Bit-Operanden, 11 Befehle';
  @override
  String get extendedDescription =>
      '256 Byte RAM, 8-Bit-Operanden, Stapel, E/A-Ports, 29 Befehle';
  @override
  String get bytesUnit => 'B';

  @override
  String get tagline => 'jedes Signal sichtbar';
  @override
  String modeTooltip(String classic, String extended) =>
      'Klassisch: $classic\nErweitert: $extended\n'
      'Umschalten löscht den RAM.';
  @override
  String get machine => 'Maschine';
  @override
  String get view => 'Ansicht';
  @override
  String get language => 'Sprache';
  @override
  String get simple => 'Einfach';
  @override
  String get detailed => 'Detailliert';
  @override
  String get aboutTooltip => 'Über GlassBox CPU';
  @override
  String get stepBackTooltip =>
      'Schritt zurück: letzten Schritt rückgängig machen';
  @override
  String get step => 'Schritt';
  @override
  String get stepCycle => 'Takt';
  @override
  String get stepCycleTooltip => 'Ein Taktzyklus (Mikroschritt)';
  @override
  String get stepInstruction => 'Befehl';
  @override
  String get stepInstructionTooltip => 'Rest des aktuellen Befehls ausführen';
  @override
  String get run => 'Start';
  @override
  String get pause => 'Pause';
  @override
  String get runTooltip => 'Bis zu einem Haltepunkt oder HLT ausführen';
  @override
  String get runToCursor => 'Bis Cursor';
  @override
  String get runToCursorTooltip =>
      'Bis zum Befehl in der Cursorzeile des Editors ausführen';
  @override
  String get reset => 'Zurücksetzen';
  @override
  String get resetTooltip => 'Geladenes Programm neu starten';
  @override
  String get halted => 'Angehalten';
  @override
  String clockState(bool high) => 'Takt ${high ? 'hoch' : 'niedrig'}';
  @override
  String get clock => 'Takt';
  @override
  String get decimalSeparator => ',';

  @override
  String get lastStep => 'Letzter Schritt';
  @override
  String get signals => 'Signale';
  @override
  String get haltedNext =>
      'Angehalten. Zurücksetzen, um das Programm erneut auszuführen.';
  @override
  String nextFetch(String instruction, String address, int? line) =>
      'Als Nächstes: $instruction an Adresse $address holen'
      '${line == null ? '' : ' · Zeile $line'}';
  @override
  String nextStep(int step, String purpose) =>
      'Als Nächstes: T$step von $purpose';

  @override
  String get bus => 'Bus';
  @override
  String get ready => 'bereit';
  @override
  String nextFetchesAt(String address) =>
      'der nächste Schritt holt den Befehl an Adresse $address';
  @override
  String get irOperand => 'IR-Operand';
  @override
  String get ioNode => 'E/A';
  @override
  String flags(int carry, int zero) => 'Flags C=$carry Z=$zero';
  @override
  String get clockStopped => 'Takt angehalten';
  @override
  String get nothingThisCycle => 'nichts zu tun in diesem Takt';
  @override
  String port(int port, String name) => 'Port $port ($name)';
  @override
  String get fetchAddress => 'Holen: Adresse des nächsten Befehls';
  @override
  String get fetchLoad => 'Holen: Befehl laden, PC erhöhen';

  @override
  String get fetch => 'Holen';
  @override
  String microcodeTitle(String name) => 'MIKROCODE · $name';
  @override
  String get unused => 'unbenutzt';
  @override
  String get groupDrive => 'Bus treiben';
  @override
  String get groupRead => 'Bus lesen';
  @override
  String get groupCounters => 'Zähler';
  @override
  String get groupAlu => 'ALU';
  @override
  String get groupControl => 'Steuerung';
  @override
  String get noteNothing => 'nichts';
  @override
  String get noteDevice => 'Gerät';
  @override
  String get noteFlags => 'Flags';
  @override
  String get noteHalt => 'Halt';

  @override
  String get aboutTitle => 'ÜBER GLASSBOX CPU';
  @override
  String get aboutIntro =>
      'Ein visueller Simulator einer 8-Bit-CPU auf dem Steckbrett: Jeder '
      'Schritt zeigt, wer den Bus treibt, wer ihn liest und warum.';
  @override
  String get aboutCredits =>
      'Basiert auf dem 8-bit CPU Simulator von {muaz}, inspiriert vom '
      '8-Bit-Steckbrett-Computer von {eater}.';
  @override
  String get licenceTitle => 'Lizenz';
  @override
  String get licenceText =>
      'Veröffentlicht unter der GNU GPL v3. Der Code des ursprünglichen '
      'Simulators steht weiterhin unter der MIT-Lizenz (siehe LICENSE und '
      'LICENSE-MIT).';
  @override
  String get quote =>
      '„Jedes komplexe System besteht nur aus einfachen Teilen, die '
      'zusammenarbeiten.“';
}
