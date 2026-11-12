import 'package:flutter/material.dart';

import 'cpu_mode.dart';

enum BuiltinProgramCategory {
  beginner('Beginner', Colors.green),
  arithmetic('Arithmetic', Colors.blue),
  controlFlow('Control Flow', Colors.orange),
  patterns('Patterns', Colors.purple),
  extended('Extended CPU', Colors.cyan);

  final String name;
  final Color color;
  const BuiltinProgramCategory(this.name, this.color);
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
STA 0xF      ; Store n (reuse A=1)
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
.equ START 10      ; Named constant

loop:  LDA count   ; Load counter
       OUT         ; Show it
       SUB one     ; Subtract 1
       STA count   ; Store it back
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
JC 0xA       ; Jump to halt, if carry flag is set
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
      code: '''; Extended CPU: 8-bit immediates, two-byte instructions
        LDI 10        ; A = 10 (opcode byte + value byte)
loop:   OUT           ; Show A
        SBI 1         ; A = A - 1, sets the zero flag
        JNZ loop      ; Repeat while A is not 0
        HLT''',
    ),

    BuiltinProgram(
      name: 'Hello (string with LDA [B])',
      description:
          'Walks a zero-terminated string with an index in B and outputs '
          'each character code: 72 69 76 76 79. Extended CPU',
      category: BuiltinProgramCategory.extended,
      mode: CpuMode.extended,
      code: '''; Extended CPU: indexed load walks a string
loop:   LDB ptr       ; B = address of the next character
        LDA [B]       ; A = RAM[B]
        CMP zero      ; End of string? (sets Z, A unchanged)
        JZ  done
        OUT           ; Show the character code
        LDA ptr       ; ptr = ptr + 1
        ADI 1
        STA ptr
        JMP loop
done:   HLT

ptr:    .db msg       ; Pointer to the string
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
      code: '''; Extended CPU: the stack grows down from 0xFF
        LDI 1
        PUSH          ; RAM[SP] = A, SP = SP - 1
        LDI 2
        PUSH
        LDI 3
        PUSH
        POP           ; SP = SP + 1, A = RAM[SP]
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
      code: '''; Extended CPU: subroutine, shifts and masks
        CALL multiply ; Push the return address, jump
        OUT           ; 143
        HLT

; result = x * y, one bit of y at a time
multiply:
        LDI 0
        STA result
next:   LDA y
        CMP zero      ; No bits left?
        JZ  finish
        AND one       ; Lowest bit of y
        JZ  shift
        LDA result    ; Bit set: result = result + x
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
        RET           ; Pop the return address

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
      code: '''; Extended CPU: shifts move a bit; carry says when it fell off
start:  LDI 1
left:   OUT
        SHL           ; Bit 7 goes into the carry
        JNC left
        LDI 0x40
right:  OUT
        SHR           ; Bit 0 goes into the carry
        JNC right
        LDI 2
        JMP left''',
    ),
  ];

  static const List<BuiltinProgram> all = [
    ...beginnerPrograms,
    ...arithmeticPrograms,
    ...controlFlowPrograms,
    ...patternsPrograms,
    ...extendedPrograms,
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
