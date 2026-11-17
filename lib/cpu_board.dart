import 'dart:async';

import 'package:flutter/material.dart';

import 'core/assembler.dart';
import 'core/cpu.dart';
import 'core/cpu_mode.dart';
import 'core/io/keypad.dart';
import 'l10n/l10n.dart';
import 'ui/hardware/hardware_controller.dart';
import 'cpu_layout.dart';
import 'ui/theme/glass.dart';

/// Drives the [Cpu] with a clock and shows its state. All CPU behaviour
/// lives in [Cpu] and [Microcode]; this widget handles timing, stepping,
/// breakpoints, step-back history and the output history.
class CPUBoard extends StatefulWidget {
  const CPUBoard({super.key});

  @override
  State<CPUBoard> createState() => _CPUBoardState();
}

/// A state saved before a step, for step-back.
typedef _HistoryEntry = ({CpuSnapshot snapshot, int outputCount});

class _CPUBoardState extends State<CPUBoard> {
  final Cpu cpu = Cpu();

  // Real board mirroring the I/O ports; it may also press keypad keys.
  late final HardwareController hardware = HardwareController(cpu)
    ..addListener(_hardwareChanged);

  void _hardwareChanged() {
    if (mounted) setState(() {});
  }

  // Clock
  Timer? clockTimer;
  Timer? singleStepTimer; // pending falling edge of a manual step
  bool clockHigh = false;
  bool isRunning = false;
  double clockSpeed = 2.0;

  // Debugging
  Set<int> breakpoints = {}; // instruction addresses
  int? cursorAddress; // instruction address on the editor cursor line
  int? runTarget; // run-to-cursor destination
  int ticksSinceRun = 0; // lets Run continue from a breakpoint

  /// States before each step, newest last, for step-back.
  final List<_HistoryEntry> history = [];
  static const int _historyLimit = 2000;

  /// Source map of the loaded program, or null.
  AssemblyResult? assembly;

  /// Every value written to the output register since the last reset.
  final List<int> outputs = [];

  // View
  bool detailedView = true;

  @override
  void initState() {
    super.initState();
    cpu.onOutput = outputs.add;
  }

  @override
  void dispose() {
    hardware.dispose();
    clockTimer?.cancel();
    singleStepTimer?.cancel();
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

  void _clearRun() {
    _stopClock();
    history.clear();
    outputs.clear();
  }

  void _onAssemble(AssemblyResult? result) {
    setState(() {
      assembly = result;
      if (result != null) {
        _clearRun();
        cpu.load(result.machineCode);
      }
    });
  }

  /// Switches machine. RAM is cleared: a program for one machine does not
  /// run on the other, so it must be assembled again.
  void _onModeChanged(CpuMode mode) {
    if (mode == cpu.mode) return;
    setState(() {
      _clearRun();
      assembly = null;
      breakpoints = {};
      cursorAddress = null;
      cpu.setMode(mode);
    });
  }

  void _onReset() {
    setState(() {
      _clearRun();
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
  /// every remaining micro-step of the current instruction. Stepping while
  /// running pauses first.
  void _onClockSingleStep({bool wholeInstruction = false}) {
    // Ignore presses while the previous step is still pending, otherwise a
    // double press runs two steps back to back.
    if (cpu.halted || singleStepTimer != null) return;

    setState(() {
      if (isRunning) _stopClock();
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

  /// Saves the state for step-back, then runs [advance] on the CPU.
  void _advance(void Function() advance) {
    history.add((snapshot: cpu.snapshot(), outputCount: outputs.length));
    if (history.length > _historyLimit) history.removeAt(0);
    advance();
  }

  void _onStepBack() {
    if (history.isEmpty || singleStepTimer != null) return;
    setState(() {
      if (isRunning) _stopClock();
      final entry = history.removeLast();
      cpu.restore(entry.snapshot);
      outputs.removeRange(entry.outputCount, outputs.length);
      clockHigh = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Glass.ground,
      body: CPULayout(
        cpu: cpu,
        assembly: assembly,
        outputs: outputs,
        clockHigh: clockHigh,
        isRunning: isRunning,
        clockSpeed: clockSpeed,
        detailedView: detailedView,
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
        onReset: _onReset,
        onModeChanged: _onModeChanged,
        onDetailedViewChanged: (detailed) {
          setState(() => detailedView = detailed);
        },
        onRamEdit: (address, value) {
          setState(() => cpu.writeRam(address, value));
        },
        onAssemble: _onAssemble,
        onBreakpointsChanged: (addresses) {
          setState(() => breakpoints = addresses);
        },
        onCursorAddressChanged: (address) {
          setState(() => cursorAddress = address);
        },
        onKeypadKey: (key) {
          setState(() => cpu.io.device<Keypad>()?.press(key));
        },
        hardware: hardware,
        onLangChanged: _onLangChanged,
      ),
    );
  }

  /// Switches language and rebuilds every widget, const ones included,
  /// keeping all state.
  void _onLangChanged(Lang lang) {
    if (lang == L10n.current) return;
    L10n.set(lang);
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
    setState(() {});
  }
}
