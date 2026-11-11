import 'dart:async';

import 'package:flutter/material.dart';

import 'core/control_word.dart';
import 'core/cpu.dart';
import 'cpu_layout.dart';

/// Drives the [Cpu] with a clock and shows its state. All CPU behaviour
/// lives in [Cpu] and [Microcode]; this widget only handles timing, the
/// manual controls and the bus animation.
class CPUBoard extends StatefulWidget {
  const CPUBoard({super.key});

  @override
  State<CPUBoard> createState() => _CPUBoardState();
}

class _CPUBoardState extends State<CPUBoard> with TickerProviderStateMixin {
  final Cpu cpu = Cpu();

  // Clock
  Timer? clockTimer;
  Timer? singleStepTimer; // pending falling edge of a manual step
  bool clockHigh = false;
  bool isRunning = false;
  double clockSpeed = 2.0;
  bool manualMode = false;

  // Animation
  late AnimationController busAnimationController;
  late Animation<double> busAnimation;

  @override
  void initState() {
    super.initState();

    busAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    busAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(busAnimationController);
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    singleStepTimer?.cancel();
    busAnimationController.dispose();
    super.dispose();
  }

  void _onLoadProgram(List<int> program) {
    setState(() => cpu.load(program));
  }

  void _onClockToggle() {
    setState(() {
      isRunning = !isRunning;
      if (isRunning && !cpu.halted) {
        _runClock();
      } else {
        clockTimer?.cancel();
      }
    });
  }

  // Timers cannot fire reliably faster than about one frame, so at high
  // speeds each timer tick runs several clock edges.
  static const int _minTickMicros = 16000;

  void _runClock() {
    final int halfPeriodMicros = (500000 / clockSpeed).round();
    final int edgesPerTick = (_minTickMicros / halfPeriodMicros).ceil();
    clockTimer = Timer.periodic(
      Duration(microseconds: halfPeriodMicros * edgesPerTick),
      (_) => _clockPulse(edgesPerTick),
    );
  }

  void _clockPulse(int edges) {
    setState(() {
      for (int i = 0; i < edges; i++) {
        if (cpu.halted) {
          clockTimer?.cancel();
          isRunning = false;
          return;
        }
        clockHigh = !clockHigh;
        if (!clockHigh) {
          _tick(cpu.tick);
        }
      }
    });
  }

  /// Manual step: one micro-step (clock cycle), or with [wholeInstruction]
  /// every remaining micro-step of the current instruction.
  void _onClockSingleStep({bool wholeInstruction = false}) {
    // Ignore presses while the previous step is still pending, otherwise a
    // double press runs two steps back to back.
    if (cpu.halted || singleStepTimer != null) return;

    setState(() {
      clockHigh = true;
    });
    singleStepTimer = Timer(const Duration(milliseconds: 100), () {
      singleStepTimer = null;
      if (!mounted) return;
      setState(() {
        clockHigh = false;
        _tick(wholeInstruction ? cpu.stepInstruction : cpu.tick);
      });
    });
  }

  /// Runs [advance] on the CPU and animates the bus if it carried a value.
  void _tick(void Function() advance) {
    advance();
    if (cpu.busActive) {
      busAnimationController.forward(from: 0);
    }
  }

  void _onReset() {
    setState(() {
      clockTimer?.cancel();
      singleStepTimer?.cancel();
      singleStepTimer = null;
      isRunning = false;
      clockHigh = false;
      cpu.reset(); // restarts the loaded program rather than wiping RAM
    });
  }

  void _onClearControlSignals() {
    cpu.controlWord = 0;
    cpu.busActive = false;
  }

  @override
  Widget build(BuildContext context) {
    final int word = cpu.controlWord;
    bool on(ControlWord signal) => signal.isActive(word);

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: CPULayout(
        // ? Bus
        bus: cpu.bus,
        busActive: cpu.busActive,

        // ? Registers
        registerA: cpu.registerA,
        registerB: cpu.registerB,
        instructionRegister: cpu.instructionRegister,
        memoryAddressRegister: cpu.memoryAddressRegister,
        programCounter: cpu.programCounter,
        outputRegister: cpu.outputRegister,
        sumRegister: cpu.sumRegister,

        // ? Flags
        carryFlag: cpu.carryFlag,
        zeroFlag: cpu.zeroFlag,

        // ? Control signals
        clockHigh: clockHigh,
        haltFlag: cpu.halted,
        memoryIn: on(ControlWord.mi),
        ramIn: on(ControlWord.ri),
        ramOut: on(ControlWord.ro),
        instructionOut: on(ControlWord.io),
        instructionIn: on(ControlWord.ii),
        aRegisterIn: on(ControlWord.ai),
        aRegisterOut: on(ControlWord.ao),
        bRegisterIn: on(ControlWord.bi),
        sumOut: on(ControlWord.so),
        subtract: on(ControlWord.su),
        outputIn: on(ControlWord.oi),
        counterEnable: on(ControlWord.ce),
        counterOut: on(ControlWord.co),
        jump: on(ControlWord.j),
        flagsIn: on(ControlWord.fi),

        // ? RAM
        ram: cpu.ram,

        // ? Clock
        isRunning: isRunning,
        clockSpeed: clockSpeed,
        manualMode: manualMode,

        // ? Animation
        busAnimation: busAnimation,

        // ? Microcode step
        microStep: cpu.microStep,
        instructionAddress: cpu.instructionAddress,

        // ? Control word
        controlWord: word,

        // ? Clock
        onClockToggle: _onClockToggle,
        onClockSingleStep: _onClockSingleStep,
        onClockInstructionStep: () =>
            _onClockSingleStep(wholeInstruction: true),
        onClockSpeedChanged: (speed) {
          setState(() {
            clockSpeed = speed;
            if (isRunning) {
              clockTimer?.cancel();
              _runClock();
            }
          });
        },
        onClockManualModeChanged: (manual) {
          setState(() {
            manualMode = manual;
          });
        },

        // ? RAM
        onRamEdit: (address, value) {
          setState(() => cpu.writeRam(address, value));
        },

        // ? CPU
        onReset: _onReset,
        onClearControlSignals: _onClearControlSignals,
        onLoadProgram: _onLoadProgram,
      ),
    );
  }
}
