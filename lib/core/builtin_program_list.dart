import 'cpu_mode.dart';

enum BuiltinProgramCategory {
  beginner('Beginner'),
  arithmetic('Arithmetic'),
  controlFlow('Control Flow'),
  patterns('Patterns'),
  extended('Extended CPU'),
  devices('I/O devices');

  final String name;
  const BuiltinProgramCategory(this.name);
}

class BuiltinProgram {
  final String name;
  final String description;
  final String code;
  final BuiltinProgramCategory category;

  /// Machine the program is written for; opening it switches to it.
  final CpuMode mode;

  const BuiltinProgram({
    required this.name,
    required this.description,
    required this.code,
    required this.category,
    this.mode = CpuMode.classic,
  });
}

class BuiltinProgramList {
  static const List<BuiltinProgram> beginnerPrograms = [
    BuiltinProgram(
      name: 'Counter (0-255)',
      description: 'Counts from 0 to 255 continuously',
      category: BuiltinProgramCategory.beginner,
      code: '''LDI #0       ; Start at 0
STA 0xF      ; Store in RAM
LDI #1       ; Increment = 1
STA 0xE      ; Store increment
LDA 0xF      ; Load counter
OUT          ; Output
ADD 0xE      ; Add 1
STA 0xF      ; Store back
JZ 0xA       ; Jump to halt, if 0
JMP 0x4      ; Loop
HLT          ; Halt''',
    ),

    BuiltinProgram(
      name: 'Binary Blinker',
      description: 'Alternates between 0 and 1 continuously',
      category: BuiltinProgramCategory.beginner,
      code: '''LDI #0       ; Load 0
OUT          ; Output
LDI #1       ; Load 1
OUT          ; Output
JMP 0x0      ; Loop''',
    ),
  ];

  static const List<BuiltinProgram> arithmeticPrograms = [
    BuiltinProgram(
      name: 'Fibonacci Sequence',
      description: 'Generates Fibonacci numbers: 0, 1, 1, 2, 3, 5, 8, 13...',
      category: BuiltinProgramCategory.arithmetic,
      code: '''LDI #0       ; a = 0
STA 0xE      ; Store a
LDI #1       ; b = 1
STA 0xF      ; Store b
LDA 0xE      ; Load a
OUT          ; Output
ADD 0xF      ; a + b
STA 0xD      ; Save temp
LDA 0xF      ; Load b
STA 0xE      ; a = b
LDA 0xD      ; Load temp
STA 0xF      ; b = temp
JMP 0x4      ; Loop''',
    ),

    BuiltinProgram(
      name: 'Powers of 2',
      description: 'Generates powers of 2: 1, 2, 4, 8, 16, 32, 64, 128...',
      category: BuiltinProgramCategory.arithmetic,
      code: '''LDI #1       ; Start with 1
STA 0xF      ; Store
LDA 0xF      ; Load
OUT          ; Output
ADD 0xF      ; Double
STA 0xF      ; Store
JZ 0x8       ; Jump to halt, if 0
JMP 0x2      ; Loop
HLT          ; Halt''',
    ),

    BuiltinProgram(
      name: 'Triangle Numbers',
      description: 'Generates triangle numbers: 1, 3, 6, 10, 15, 21, 28...',
      category: BuiltinProgramCategory.arithmetic,
      code: '''LDI #1       ; Load 1
STA 0xD      ; Store inc
STA 0xF      ; n = 1 (A is 1)
LDI #0       ; sum = 0
STA 0xE      ; Store sum
LDA 0xE      ; Load sum
ADD 0xF      ; Add n
STA 0xE      ; Store sum
OUT          ; Output
LDA 0xF      ; Load n
ADD 0xD      ; n + 1
STA 0xF      ; Store n
JMP 0x5      ; Loop''',
    ),

    BuiltinProgram(
      name: 'Square Numbers',
      description: 'Generates squares: 1, 4, 9, 16, 25, 36, 49, 64...',
      category: BuiltinProgramCategory.arithmetic,
      code: '''LDI #2       ; inc = 2
STA 0xD      ; Store at 0xD
LDI #1       ; odd = 1
STA 0xE      ; Store at 0xE
LDI #0       ; square = 0
ADD 0xE      ; Add odd
OUT          ; Output
STA 0xF      ; Store square
LDA 0xE      ; Load odd
ADD 0xD      ; Add 2
STA 0xE      ; Store odd
LDA 0xF      ; Load square
JMP 0x5      ; Loop to addr 5''',
    ),

    BuiltinProgram(
      name: 'Multiplication (7 × 3)',
      description: 'Multiplies 7 by 3 using repeated addition, outputs 21',
      category: BuiltinProgramCategory.arithmetic,
      code: '''LDI #7       ; Load 7
STA 0xF      ; Store at 0xF
ADD 0xF      ; 7 + 7 = 14
ADD 0xF      ; 14 + 7 = 21
OUT          ; Output 21
HLT          ; Halt''',
    ),
  ];

  static const List<BuiltinProgram> controlFlowPrograms = [
    BuiltinProgram(
      name: 'Countdown from 10',
      description: 'Counts down from 10 to 0 and halts',
      category: BuiltinProgramCategory.controlFlow,
      code: '''LDI #10      ; Start at 10
STA 0xF      ; Store
LDI #1       ; dec = 1
STA 0xE      ; Store
LDA 0xF      ; Load
OUT          ; Output
SUB 0xE      ; Subtract 1
STA 0xF      ; Store
JZ 0xA       ; Jump to halt, if 0
JMP 0x4      ; Loop
HLT          ; Halt''',
    ),

    BuiltinProgram(
      name: 'Countdown (labels & data)',
      description:
          'The countdown again, with labels, a constant and data bytes '
          'instead of raw addresses',
      category: BuiltinProgramCategory.controlFlow,
      code: '''; Labels replace raw addresses
.equ START 10 ; Named constant

loop:  LDA count   ; Load counter
       OUT         ; Show it
       SUB one     ; Subtract 1
       STA count   ; Store back
       JZ  done    ; Stop at 0
       JMP loop    ; Repeat
done:  HLT         ; Halt

count: .db START   ; Counter byte
one:   .db 1       ; Constant 1''',
    ),
  ];

  static const List<BuiltinProgram> patternsPrograms = [
    BuiltinProgram(
      name: 'Even Numbers',
      description: 'Outputs even numbers: 0, 2, 4, 6, 8, 10...',
      category: BuiltinProgramCategory.patterns,
      code: '''LDI #0       ; Start at 0
STA 0xF      ; Store
LDI #2       ; inc = 2
STA 0xE      ; Store
LDA 0xF      ; Load
OUT          ; Output
ADD 0xE      ; Add 2
STA 0xF      ; Store
JZ 0xA       ; Jump to halt, if 0
JMP 0x4      ; Loop
HLT          ; Halt''',
    ),

    BuiltinProgram(
      name: 'Multiples of 5',
      description: 'Outputs multiples of 5: 0, 5, 10, 15, 20, 25...',
      category: BuiltinProgramCategory.patterns,
      code: '''LDI #0       ; Start at 0
STA 0xF      ; Store
LDI #5       ; inc = 5
STA 0xE      ; Store
LDA 0xF      ; Load
OUT          ; Output
ADD 0xE      ; Add 5
STA 0xF      ; Store
JC 0xA       ; Halt on carry
JMP 0x4      ; Loop
HLT          ; Halt''',
    ),

    BuiltinProgram(
      name: 'Alternating Pattern',
      description: 'Alternates between 10 and 20',
      category: BuiltinProgramCategory.patterns,
      code: '''LDI #10      ; Load 10
OUT          ; Output
LDI #5       ; Load 5
OUT          ; Output
JMP 0x0      ; Loop''',
    ),
  ];

  static const List<BuiltinProgram> extendedPrograms = [
    BuiltinProgram(
      name: 'Countdown (immediates & JNZ)',
      description:
          'Counts down from 10 with SBI and JNZ: no data bytes needed. '
          'Extended CPU',
      category: BuiltinProgramCategory.extended,
      mode: CpuMode.extended,
      code: '''; Extended CPU: 8-bit immediates
; and two-byte instructions
        ; Opcode byte + value byte
        LDI 10        ; A = 10
loop:   OUT           ; Show A
        SBI 1         ; A-1, sets Z
        JNZ loop      ; Until A = 0
        HLT''',
    ),

    BuiltinProgram(
      name: 'Hello (string with LDA [B])',
      description:
          'Walks a zero-terminated string with an index in B and outputs '
          'each character code: 72 69 76 76 79. Extended CPU',
      category: BuiltinProgramCategory.extended,
      mode: CpuMode.extended,
      code: '''; Extended CPU: an indexed load
; walks a string
        ; B = next char's address
loop:   LDB ptr
        LDA [B]       ; A = RAM[B]
        ; End of string? (sets Z,
        ; A unchanged)
        CMP zero
        JZ  done
        OUT           ; Char code
        LDA ptr       ; ptr + 1
        ADI 1
        STA ptr
        JMP loop
done:   HLT

ptr:    .db msg       ; → string
zero:   .db 0
msg:    .db "HELLO", 0''',
    ),

    BuiltinProgram(
      name: 'Stack reverse (PUSH / POP)',
      description:
          'Pushes 1, 2, 3 and pops them back: the stack gives them in '
          'reverse, 3 2 1. Extended CPU',
      category: BuiltinProgramCategory.extended,
      mode: CpuMode.extended,
      code: '''; Extended CPU: the stack grows
; down from 0xFF
        LDI 1
        ; RAM[SP] = A, SP = SP - 1
        PUSH
        LDI 2
        PUSH
        LDI 3
        PUSH
        ; SP = SP + 1, A = RAM[SP]
        POP
        OUT           ; 3
        POP
        OUT           ; 2
        POP
        OUT           ; 1
        HLT''',
    ),

    BuiltinProgram(
      name: 'Multiply (CALL, shifts, AND)',
      description:
          'A shift-and-add multiply subroutine: 13 × 11 = 143. Extended CPU',
      category: BuiltinProgramCategory.extended,
      mode: CpuMode.extended,
      code: '''; Extended CPU: a subroutine,
; shifts and masks
        ; Push return address, jump
        CALL multiply
        OUT           ; 143
        HLT

; result = x * y, one bit of y
; at a time
multiply:
        LDI 0
        STA result
next:   LDA y
        CMP zero      ; y = 0?
        JZ  finish
        AND one       ; Low bit of y
        JZ  shift
        ; Bit set: result += x
        LDA result
        ADD x
        STA result
shift:  LDA x         ; x = x * 2
        SHL
        STA x
        LDA y         ; y = y / 2
        SHR
        STA y
        JMP next
finish: LDA result
        RET           ; Pop, return

x:      .db 13
y:      .db 11
result: .db 0
zero:   .db 0
one:    .db 1''',
    ),

    BuiltinProgram(
      name: 'Bouncing bit (SHL / SHR)',
      description:
          'A lit bit runs left to bit 7 and back: 1 2 4 … 128 64 … 1. '
          'The carry flag catches the bit that falls off. Extended CPU',
      category: BuiltinProgramCategory.extended,
      mode: CpuMode.extended,
      code: '''; Extended CPU: shifts move a bit;
; the carry says when it fell off
start:  LDI 1
left:   OUT
        SHL           ; Bit 7 → C
        JNC left
        LDI 0x40
right:  OUT
        SHR           ; Bit 0 → C
        JNC right
        LDI 2
        JMP left''',
    ),
  ];

  /// Programs for the devices on the I/O ports (Extended CPU): text LCD
  /// on ports 1-2, LED matrix on 3-4, keypad on 5.
  static const List<BuiltinProgram> devicePrograms = [
    BuiltinProgram(
      name: 'LCD: Hello, world',
      description:
          'Initialises the 16x2 LCD, then writes two lines from a string '
          'with OUT 2. A newline byte moves to line 2.',
      category: BuiltinProgramCategory.devices,
      mode: CpuMode.extended,
      code: '''; Text LCD: port 1 takes commands,
; port 2 characters
.equ LCD_CMD 1
.equ LCD_DATA 2
        ; function set: 8-bit bus,
        ; 2 lines
        LDI 0x38
        OUT LCD_CMD
        ; display on (starts off),
        ; no cursor
        LDI 0x0C
        OUT LCD_CMD
        ; clear, cursor to top left
        LDI 0x01
        OUT LCD_CMD
        ; B = next char's address
loop:   LDB ptr
        LDA [B]
        CMP zero      ; end?
        JZ  done
        CMP newline   ; line 2?
        JZ  line2
        ; show it; the cursor moves
        OUT LCD_DATA
next:   LDA ptr
        ADI 1
        STA ptr
        JMP loop
        ; DDRAM address 0x40: line 2
line2:  LDI 0xC0
        OUT LCD_CMD
        JMP next
done:   HLT

ptr:     .db msg
zero:    .db 0
newline: .db 10
msg:     .db "Hello, world!\\nGlassBox CPU", 0''',
    ),
    BuiltinProgram(
      name: 'LCD: custom character',
      description:
          'Draws a heart in CGRAM as character 0, then prints it between '
          'words: "I <heart> CPU".',
      category: BuiltinProgramCategory.devices,
      mode: CpuMode.extended,
      code: '''; Custom LCD character: 8 rows
; of 5 pixels in CGRAM
.equ LCD_CMD 1
.equ LCD_DATA 2
        ; 8-bit bus, 2 lines
        LDI 0x38
        OUT LCD_CMD
        LDI 0x0C      ; display on
        OUT LCD_CMD
        LDI 0x01      ; clear
        OUT LCD_CMD
        ; CGRAM address 0: char 0,
        ; top row
        LDI 0x40
        OUT LCD_CMD
        ; the heart, a row per byte
glyph:  LDB gptr
        LDA [B]
        OUT LCD_DATA
        LDA gptr
        ADI 1
        STA gptr
        LDA count
        SBI 1
        ; STA keeps SBI's flags
        STA count
        JNZ glyph
        ; back to DDRAM: line 1,
        ; column 0
        LDI 0x80
        OUT LCD_CMD
text:   LDB tptr
        LDA [B]
        ; 0xFF ends the text;
        ; 0 is the heart
        CMP end
        JZ  done
        OUT LCD_DATA
        LDA tptr
        ADI 1
        STA tptr
        JMP text
done:   HLT

gptr:   .db heart
tptr:   .db msg
count:  .db 8
end:    .db 0xFF
heart:  .db 0, 10, 31, 31, 31, 14, 4, 0
msg:    .db "I ", 0, " CPU", 0xFF''',
    ),
    BuiltinProgram(
      name: 'LED matrix: smiley',
      description:
          'Selects row 0, then writes eight row bytes to the 8x8 matrix; it '
          'moves to the next row after each one.',
      category: BuiltinProgramCategory.devices,
      mode: CpuMode.extended,
      code: '''; LED matrix: port 3 selects a row,
; port 4 lights it
.equ ROW 3
.equ PIXELS 4
        LDI 0
        OUT ROW       ; top row
loop:   LDB ptr
        ; one row: bit 7 is the
        ; left column
        LDA [B]
        ; the matrix then moves to
        ; the next row
        OUT PIXELS
        LDA ptr
        ADI 1
        STA ptr
        LDA count
        SBI 1
        STA count
        JNZ loop
        HLT

ptr:    .db face
count:  .db 8
face:   .db 0b00111100, 0b01000010, 0b10100101, 0b10000001
        .db 0b10100101, 0b10011001, 0b01000010, 0b00111100''',
    ),
    BuiltinProgram(
      name: 'Keypad echo',
      description:
          'Waits for keypad presses (IN 5) and shows each key on the LCD '
          'and the display. Runs until reset; try a faster clock.',
      category: BuiltinProgramCategory.devices,
      mode: CpuMode.extended,
      code: '''; Keypad on port 5: IN gives the
; ASCII code of the last key
; pressed, once, or 0 when no key
; is waiting.
.equ LCD_CMD 1
.equ LCD_DATA 2
.equ KEYPAD 5
        ; 8-bit bus, 2 lines
        LDI 0x38
        OUT LCD_CMD
        ; display on, cursor on
        LDI 0x0E
        OUT LCD_CMD
        LDI 0x01      ; clear
        OUT LCD_CMD
wait:   IN  KEYPAD    ; key or 0
        ; IN sets no flags, so
        ; compare to test
        CMP zero
        JZ  wait      ; none yet
        ; ASCII goes straight to
        ; the LCD
        OUT LCD_DATA
        OUT           ; and port 0
        JMP wait

zero:   .db 0''',
    ),
  ];

  static const List<BuiltinProgram> all = [
    ...beginnerPrograms,
    ...arithmeticPrograms,
    ...controlFlowPrograms,
    ...patternsPrograms,
    ...extendedPrograms,
    ...devicePrograms,
  ];

  static List<BuiltinProgram> getByCategory(BuiltinProgramCategory category) {
    return all.where((program) => program.category == category).toList();
  }

  static List<BuiltinProgramCategory> getCategories() {
    final categories = all.map((p) => p.category).toSet().toList();
    return categories;
  }

  static BuiltinProgram? getByName(String name) {
    try {
      return all.firstWhere((p) => p.name == name);
    } catch (e) {
      return null;
    }
  }
}
