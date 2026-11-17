# GlassBox CPU Simulator

An interactive, visual simulator of an 8-bit breadboard CPU, built with Flutter. Write a program in assembly, assemble it into RAM, and watch every clock cycle: which control signals are on, what drives the bus, which register latches it, and why.

Live demo: [glassbox.dubuisson.ch](https://glassbox.dubuisson.ch)

## Preview
<img width="1455" height="914" alt="GlassBox CPU Simulator" src="https://github.com/user-attachments/assets/3062b563-9934-4d44-aa33-f08776b2b823" />

## Table of Contents

- [Features](#features)
- [Languages](#languages)
- [Two CPUs: Classic and Extended](#two-cpus-classic-and-extended)
- [CPU Architecture](#cpu-architecture)
- [Instruction Set](#instruction-set)
  - [Classic instructions](#classic-instructions)
  - [Extended instructions](#extended-instructions)
  - [I/O ports](#io-ports)
- [Writing Assembly Programs](#writing-assembly-programs)
- [Built-in Programs](#built-in-programs)
- [Real Hardware](#real-hardware)
- [Technical Details](#technical-details)
- [Getting Started](#getting-started)
- [License](#license)

## Features

**Watching the machine**

- **Datapath view:** the registers, ALU, flags, RAM and output sit around the shared bus. The value on the bus, the component driving it and the one latching it are highlighted at every step.
- **Narration:** a strip above the board explains the last step in words, for example `PC = 0x00 → bus → MAR`, with its purpose ("fetch: address of the next instruction").
- **Microcode panel:** shows the control-word steps (T-states) of the current instruction, with the active signals grouped by role (memory, registers, ALU, program counter, stack, I/O).
- **Simple / Detailed views:** Simple shows the datapath only. Detailed adds the microcode panel and the active signals next to the narration.
- **Values everywhere:** registers show binary, hex and decimal. The display port keeps a history of its last outputs.

**Controlling execution**

- **Run / pause** with a clock from 0.25 Hz to 1 kHz.
- **Step** one clock cycle, or one whole instruction.
- **Step back:** undoes up to 2,000 cycles, including memory, output and device changes.
- **Run to cursor**, and **breakpoints** set in the editor gutter.
- **Reset** reloads the assembled program.

**Programming**

- **Built-in assembler** with labels, named constants (`.equ`), data bytes and strings (`.db`), and decimal, hex, binary and character literals. Errors point at the offending line.
- **Editor** with syntax highlighting. The line being executed is highlighted while the program runs.
- **Editable RAM:** click any byte to change it. The RAM panel disassembles memory back into instructions and labels.
- **Built-in programs:** 21 example programs in six categories. Opening one switches to the CPU it needs.
- **Instruction set reference:** a dialog with every instruction, its operand, effect, flags and an example.

**Devices and hardware** (Extended CPU)

- A **16×2 text LCD** (HD44780 command set, custom characters), an **8×8 LED matrix** and a **4×4 keypad** on I/O ports.
- **Real hardware bridge:** mirror the ports to a physical LCD, LED matrix, OLED and keypad over USB serial or Wi-Fi.

## Languages

The interface is available in **English**, **French** and **German**. Use the EN / FR / DE switch in the top bar. On a first visit the browser's language is used, and the choice is remembered.

Everything is translated: controls and tooltips, the step narration, panels and devices, program names and descriptions, assembler errors, and the instruction set reference. Instruction mnemonics (`LDA`, `OUT`), signal names (`CO`, `MI`) and the source code of the built-in programs stay as they are, so programs read the same in every language.

## Two CPUs: Classic and Extended

The chip in the editor header switches between two machines. Switching clears RAM.

- **Classic** (the default) is the 8-bit breadboard computer popularised by Ben Eater: 16 bytes of RAM, a 4-bit program counter, and eleven one-byte instructions with the operand in the low nibble.
- **Extended** keeps the same bus and fetch cycle, widened to 256 bytes of RAM with an 8-bit PC, MAR and stack pointer. Opcodes are a whole byte, followed by an operand byte when the instruction takes one. It adds logic and shift operations, compare, a stack with subroutine calls, indexed loads and I/O ports.

## CPU Architecture

| Component | Classic | Extended | Description                                                   |
| --------- | ------- | -------- | ------------------------------------------------------------- |
| **A**     | 8-bit   | 8-bit    | Accumulator; the ALU's first input and destination            |
| **B**     | 8-bit   | 8-bit    | The ALU's second input; ALU instructions load it from RAM     |
| **ALU**   | add/sub | + AND, OR, XOR, shifts | Computes from A and B                          |
| **Flags** | C, Z    | C, Z     | Carry (carry out, or borrow on subtract) and Zero, latched on `FI` |
| **PC**    | 4-bit   | 8-bit    | Program counter                                               |
| **MAR**   | 4-bit   | 8-bit    | Memory address register                                       |
| **IR**    | 8-bit   | 8-bit    | Instruction register                                          |
| **SP**    | –       | 8-bit    | Stack pointer; the stack grows down from 0xFF                 |
| **RAM**   | 16 B    | 256 B    | 8-bit words                                                   |
| **OUT**   | 8-bit   | 8-bit    | Output register, shown on the display (port 0)                |
| **Bus**   | 8-bit   | 8-bit    | Shared by all components; one driver per step                 |

## Instruction Set

### Classic instructions

One byte each: the 4-bit opcode in the high nibble, the 4-bit operand (address or value, 0–15) in the low nibble. All of them also exist in Extended mode, with the same number (`LDA` is 0x1 in Classic and 0x01 in Extended).

| Mnemonic | Opcode | Format     | Effect                                   | Flags |
| -------- | ------ | ---------- | ---------------------------------------- | ----- |
| **NOP**  | 0x0    | `NOP`      | No operation                             |       |
| **LDA**  | 0x1    | `LDA addr` | A = RAM[addr]                            |       |
| **ADD**  | 0x2    | `ADD addr` | A = A + RAM[addr]                        | C, Z  |
| **SUB**  | 0x3    | `SUB addr` | A = A − RAM[addr]; C is set on a borrow  | C, Z  |
| **STA**  | 0x4    | `STA addr` | RAM[addr] = A                            |       |
| **LDI**  | 0x5    | `LDI #val` | A = val                                  |       |
| **JMP**  | 0x6    | `JMP addr` | Jump to addr                             |       |
| **JC**   | 0x7    | `JC addr`  | Jump if carry is set                     |       |
| **JZ**   | 0x8    | `JZ addr`  | Jump if zero is set                      |       |
| **OUT**  | 0xE    | `OUT`      | Output register = A                      |       |
| **HLT**  | 0xF    | `HLT`      | Stop the clock                           |       |

### Extended instructions

Added in Extended mode. Addresses and values are a full byte; immediates range from −128 to 255.

| Mnemonic                 | Opcode      | Format      | Effect                                                   | Flags |
| ------------------------ | ----------- | ----------- | -------------------------------------------------------- | ----- |
| **JNC** / **JNZ**        | 0x09 / 0x0A | `JNZ addr`  | Jump if carry / zero is clear                            |       |
| **LDB**                  | 0x0B        | `LDB addr`  | B = RAM[addr]                                            |       |
| **ADI** / **SBI**        | 0x0C / 0x0D | `ADI #val`  | A = A ± val                                              | C, Z  |
| **AND** / **OR** / **XOR** | 0x10–0x12 | `AND addr`  | A = A op RAM[addr]; clears carry                         | C, Z  |
| **CMP**                  | 0x13        | `CMP addr`  | Flags from A − RAM[addr]; A unchanged (C = 1 when A is smaller) | C, Z |
| **SHL** / **SHR**        | 0x14 / 0x15 | `SHL`       | Shift A one bit; the bit shifted out goes into carry     | C, Z  |
| **OUT port**             | 0x18        | `OUT 2`     | Write A to the device on a port                          |       |
| **IN port**              | 0x19        | `IN 5`      | A = value read from the device on a port                 |       |
| **PUSH** / **POP**       | 0x20 / 0x21 | `PUSH`      | Save / restore A on the stack                            |       |
| **CALL**                 | 0x22        | `CALL addr` | Push the return address and jump                         |       |
| **RET**                  | 0x23        | `RET`       | Return from the subroutine                               |       |
| **LDA [B]**              | 0x30        | `LDA [B]`   | A = RAM[B] (arrays, strings)                             |       |

The ALU always works on A and B, so ADD, SUB, AND, OR, XOR, CMP, ADI and SBI overwrite B.

### I/O ports

`OUT port` latches the port number into the port register, then A drives the bus and the device on that port reads it. `IN port` has the device drive the bus into A. Plain `OUT` is port 0, so Classic programs behave the same in Extended mode. An unconnected port reads 0.

| Port | Device                    | Direction | Use                                                                    |
| ---- | ------------------------- | --------- | ---------------------------------------------------------------------- |
| 0    | Display (output register) | out       | Plain `OUT` or `OUT 0`                                                 |
| 1    | Text LCD 16×2: command    | out       | HD44780 instructions: `0x38` 2 lines, `0x0C` display on, `0x01` clear, `0x80+addr` cursor (line 2 at `0x40`), `0x40+addr` custom characters. `IN 1` reads the cursor address |
| 2    | Text LCD 16×2: data       | out       | A character at the cursor, which then moves on                         |
| 3    | LED matrix 8×8: row       | out       | Selects the row (0–7) for the next data byte                           |
| 4    | LED matrix 8×8: data      | out       | The row's LEDs, bit 7 on the left; the next row is selected after it   |
| 5    | Keypad 4×4                | in        | ASCII of the last key pressed (`0`–`9`, `A`–`D`, `*`, `#`), read once; 0 if none |

Like the real HD44780, the LCD starts with its display off: send `0x38` and `0x0C` first.

## Writing Assembly Programs

Each line is `[label:] [instruction | directive] [; comment]`.

- **Operands** may be decimal, hex (`0x1F`), binary (`0b1010`), a character (`'A'`), or a label or constant name. A leading `#` is optional.
- **Labels** (`loop:`) name the address of the next instruction or data byte.
- **`.equ NAME value`** defines a named constant.
- **`.db`** places data bytes: values, labels, strings (`"Hello"`) or characters.
- Names are not case-sensitive.

```assembly
; Labels replace raw addresses
.equ START 10 ; Named constant

loop:  LDA count   ; Load counter
       OUT         ; Show it
       SUB one     ; Subtract 1
       STA count   ; Store back
       JZ  done    ; Stop at 0
       JMP loop    ; Repeat
done:  HLT         ; Halt

count: .db START   ; Counter byte
one:   .db 1       ; Constant 1
```

## Built-in Programs

| Category       | Programs                                                                                          |
| -------------- | ------------------------------------------------------------------------------------------------- |
| Beginner       | Counter (0–255), Binary Blinker                                                                   |
| Arithmetic     | Fibonacci Sequence, Powers of 2, Triangle Numbers, Square Numbers, Multiplication (7 × 3)         |
| Control Flow   | Countdown from 10, Countdown (labels & data)                                                      |
| Patterns       | Even Numbers, Multiples of 5, Alternating Pattern                                                 |
| Extended CPU   | Countdown (immediates & JNZ), Hello (string with LDA [B]), Stack reverse (PUSH / POP), Multiply (CALL, shifts, AND), Bouncing bit (SHL / SHR) |
| I/O devices    | LCD: Hello, world · LCD: custom character · LED matrix: smiley · Keypad echo                      |

## Real Hardware

The *Real hardware* button in the I/O devices panel mirrors the ports to a real LCD, LED matrix, OLED and keypad, over USB serial or Wi-Fi. Firmware is included for Arduino Uno/Nano/Mega, ESP32 and Raspberry Pi Pico (`firmware/arduino`), and for Raspberry Pi (`firmware/raspberry-pi`). Wiring, setup and the protocol are described in [docs/hardware-bridge.md](docs/hardware-bridge.md).

## Technical Details

### Fetch-execute cycle

Every instruction starts with the same two fetch steps, then runs its own execute steps:

1. **T0:** `CO|MI` — PC → MAR.
2. **T1:** `RO|II|CE` — RAM[MAR] → IR, then PC + 1.
3. **T2 onwards:** the instruction's own steps. An instruction with nothing to do still spends one empty step, so NOP, HLT and an untaken Classic jump take three cycles.

In Extended mode the operand is the byte after the opcode, so an execute step reads it at the program counter and moves past it (`CO|MI`, then `RO|..|CE`).

### Control signals

| Signal | Meaning                    | Signal | Meaning                         |
| ------ | -------------------------- | ------ | ------------------------------- |
| HLT    | Halt the clock             | SU     | ALU subtracts                   |
| MI     | Memory address in          | OI     | Output register in              |
| RI     | RAM in (write)             | CE     | Counter enable (PC + 1)         |
| RO     | RAM out (read)             | CO     | Counter out                     |
| IO     | Instruction operand out    | J      | Jump (load PC)                  |
| II     | Instruction register in    | FI     | Flags in                        |
| AI     | A in                       | AO     | A out                           |
| BI     | B in                       | SO     | ALU (sum) out                   |

Extended mode adds twelve signals: **BO** (B out), **SPO** (stack pointer out), **SP+** / **SP−** (stack pointer up / down), the ALU selects **AN**, **OR**, **XR**, **SL**, **SR**, and the I/O signals **PI** (port register in), **DI** (device in) and **DO** (device out).

### Microcode

Each instruction is a list of control words, one per step: what the EEPROMs hold in the breadboard computer. For example:

```
ADD addr (Classic)            CALL addr (Extended)
  T0: CO|MI                     T0: CO|MI
  T1: RO|II|CE                  T1: RO|II|CE
  T2: IO|MI                     T2: SPO|MI       ; SP → MAR
  T3: RO|BI                     T3: CO|RI|SP−    ; save PC, SP − 1
  T4: SO|AI|FI                  T4: CO|MI        ; operand address → MAR
                                T5: RO|J         ; jump to operand
```

## Getting Started

### Prerequisites

- Flutter SDK with Dart 3.10 or later (developed with Flutter 3.50)

### Installation

1. Clone the repository:

```bash
git clone https://github.com/jimbotonic/glassbox-cpu.git
cd glassbox-cpu
```

2. Install Flutter (skip if `flutter --version` already works). The scripts clone the stable SDK into `~/dev/flutter` (`%USERPROFILE%\dev\flutter` on Windows), add it to your PATH and run `flutter pub get`:

```bash
bash scripts/install_flutter.sh                  # Linux (add --linux-desktop for flutter run -d linux)
powershell -ExecutionPolicy Bypass -File scripts\install_flutter.ps1   # Windows
```

3. Install dependencies and run:

```bash
flutter pub get
flutter run -d chrome
```

To build the web version: `flutter build web --release` (output in `build/web`). Run the tests with `flutter test`.

### Screen size

The board needs a window of at least 1340 × 640 px. The Extended CPU's devices get their own column from about 1900 px wide; below that they sit under the datapath.

## Contributing

Bug reports, feature requests and pull requests are welcome.

## License

GlassBox CPU is licensed under the GNU General Public License v3.0 — see [LICENSE](LICENSE).

It is based on [8-bit CPU Simulator](https://github.com/devmuaz/8bit-CPU-Simulator) by [devmuaz](https://devmuaz.com),
released under the MIT License — see [LICENSE-MIT](LICENSE-MIT) and [NOTICE](NOTICE).
Inspired by [Ben Eater](https://eater.net)'s 8-bit breadboard computer.
