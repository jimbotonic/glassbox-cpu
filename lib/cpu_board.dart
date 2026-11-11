import 'dart:async';

import 'package:flutter/material.dart';

import 'core/cpu.dart';
import 'cpu_layout.dart';

/// Drives the [Cpu] with a clock and shows its state. All CPU behaviour
/// lives in [Cpu] and [Microcode]; this widget handles timing, the manual
/// controls, breakpoints, step-back history and the bus animation.
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

  // Debugging
  Set<int> breakpoints = {}; // instruction addresses
  int? cursorAddress; // instruction address on the editor cursor line
  int? runTarget; // run-to-cursor destination
  int ticksSinceRun = 0; // lets Run continue from a breakpoint

  /// States before each step, newest last, for step-back.
  final List<CpuSnapshot> history = [];
  static const int _historyLimit = 2000;

  // View
  bool detailedView = true;

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

  /// Address whose source line the editor highlights: the instruction
  /// about to run when between instructions, else the one running.
  int get _highlightAddress =>
      cpu.atInstructionStart ? cpu.programCounter : cpu.instructionAddress;

  void _stopClock() {
    clockTimer?.cancel();
    singleStepTimer?.cancel();
    singleStepTimer = null;
    isRunning = false;
    clockHigh = false;
    runTarget = null;
  }

  void _onLoadProgram(List<int> program) {
    setState(() {
      _stopClock();
      history.clear();
      cpu.load(program);
    });
  }

  void _onReset() {
    setState(() {
      _stopClock();
      history.clear();
      cpu.reset(); // restarts the loaded program rather than wiping RAM
    });
  }

  void _startClock({int? target}) {
    runTarget = target;
    ticksSinceRun = 0;
    isRunning = true;
    _runClock();
  }

  void _onClockToggle() {
    setState(() {
      if (isRunning) {
        _stopClock();
      } else if (!cpu.halted) {
        _startClock();
      }
    });
  }

  void _onRunToCursor() {
    if (cursorAddress == null || cpu.halted) return;
    setState(() {
      clockTimer?.cancel();
      _startClock(target: cursorAddress);
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

  /// Whether the run should pause before the instruction at the program
  /// counter: a breakpoint or the run-to-cursor target. The instruction the
  /// run started on never stops it, so Run continues past a breakpoint.
  bool get _shouldPause =>
      cpu.atInstructionStart &&
      ticksSinceRun > 0 &&
      (breakpoints.contains(cpu.programCounter) ||
          cpu.programCounter == runTarget);

  void _clockPulse(int edges) {
    setState(() {
      for (int i = 0; i < edges; i++) {
        if (cpu.halted || _shouldPause) {
          _stopClock();
          return;
        }
        clockHigh = !clockHigh;
        if (!clockHigh) {
          _advance(cpu.tick);
          ticksSinceRun++;
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
        _advance(wholeInstruction ? cpu.stepInstruction : cpu.tick);
      });
    });
  }

  /// Saves the state for step-back, runs [advance] on the CPU, and animates
  /// the bus if it carried a value.
  void _advance(void Function() advance) {
    history.add(cpu.snapshot());
    if (history.length > _historyLimit) history.removeAt(0);
    advance();
    if (cpu.busActive) {
      busAnimationController.forward(from: 0);
    }
  }

  void _onStepBack() {
    if (history.isEmpty || singleStepTimer != null) return;
    setState(() {
      cpu.restore(history.removeLast());
      clockHigh = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: CPULayout(
        cpu: cpu,
        clockHigh: clockHigh,
        isRunning: isRunning,
        clockSpeed: clockSpeed,
        manualMode: manualMode,
        detailedView: detailedView,
        busAnimation: busAnimation,
        highlightAddress: _highlightAddress,
        onClockToggle: _onClockToggle,
        onClockSingleStep: _onClockSingleStep,
        onClockInstructionStep: () =>
            _onClockSingleStep(wholeInstruction: true),
        onStepBack: history.isEmpty ? null : _onStepBack,
        onRunToCursor: cursorAddress == null || cpu.halted
            ? null
            : _onRunToCursor,
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
            if (manual) _stopClock();
            manualMode = manual;
          });
        },
        onReset: _onReset,
        onDetailedViewChanged: (detailed) {
          setState(() => detailedView = detailed);
        },
        onRamEdit: (address, value) {
          setState(() => cpu.writeRam(address, value));
        },
        onLoadProgram: _onLoadProgram,
        onBreakpointsChanged: (addresses) {
          setState(() => breakpoints = addresses);
        },
        onCursorAddressChanged: (address) {
          setState(() => cursorAddress = address);
        },
      ),
    );
  }
}
