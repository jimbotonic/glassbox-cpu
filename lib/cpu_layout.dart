import 'package:flutter/material.dart';

import 'core/assembler.dart';
import 'core/cpu.dart';
import 'core/cpu_mode.dart';
import 'core/step_info.dart';
import 'l10n/l10n.dart';
import 'ui/about_dialog.dart';
import 'ui/board/datapath.dart';
import 'ui/board/devices_panel.dart';
import 'ui/hardware/hardware_controller.dart';
import 'ui/board/microcode_panel.dart';
import 'ui/board/narration_strip.dart';
import 'ui/board/ram_panel.dart';
import 'ui/board/top_bar.dart';
import 'ui/editor/code_editor.dart';

/// The board: controls on top, the last step in words, then memory, the
/// datapath around the bus, and the program editor, filling the window.
class CPULayout extends StatelessWidget {
  final Cpu cpu;
  final AssemblyResult? assembly;
  final List<int> outputs;

  // Clock
  final bool clockHigh;
  final bool isRunning;
  final double clockSpeed;

  // View
  final bool detailedView;

  /// RAM address whose source line the editor highlights.
  final int highlightAddress;

  // Clock controls
  final VoidCallback onClockToggle;
  final VoidCallback onClockSingleStep;
  final VoidCallback onClockInstructionStep;
  final VoidCallback? onStepBack;
  final VoidCallback? onRunToCursor;
  final ValueChanged<double> onClockSpeedChanged;
  final VoidCallback onReset;

  // View controls
  final ValueChanged<bool> onDetailedViewChanged;
  final ValueChanged<CpuMode> onModeChanged;

  // Program
  final void Function(int address, int value) onRamEdit;
  final ValueChanged<AssemblyResult?> onAssemble;
  final ValueChanged<Set<int>> onBreakpointsChanged;
  final ValueChanged<int?> onCursorAddressChanged;

  // Devices
  final ValueChanged<String> onKeypadKey;
  final HardwareController hardware;

  // Language
  final ValueChanged<Lang> onLangChanged;

  const CPULayout({
    super.key,
    required this.cpu,
    required this.assembly,
    required this.outputs,
    required this.clockHigh,
    required this.isRunning,
    required this.clockSpeed,
    required this.detailedView,
    required this.highlightAddress,
    required this.onClockToggle,
    required this.onClockSingleStep,
    required this.onClockInstructionStep,
    required this.onStepBack,
    required this.onRunToCursor,
    required this.onClockSpeedChanged,
    required this.onReset,
    required this.onDetailedViewChanged,
    required this.onModeChanged,
    required this.onRamEdit,
    required this.onAssemble,
    required this.onBreakpointsChanged,
    required this.onCursorAddressChanged,
    required this.onKeypadKey,
    required this.hardware,
    required this.onLangChanged,
  });

  static const double _gap = 14;

  /// The editor takes about 28% of the board, so long comment lines fit on
  /// wide screens, within 420–560 px.
  static double editorWidth(double boardWidth) =>
      (boardWidth * 0.28).clamp(420.0, 560.0);

  static const double _ramWidth = 300;

  /// Width of the I/O devices column, beside the datapath.
  static const double _devicesWidth = 400;

  /// Centre width from which the devices get their own column (about a
  /// 1900 px window); below it they stack under the datapath.
  static const double _devicesColumnFrom = 1000;

  /// Width left for the centre column on a board [boardWidth] wide.
  static double centreWidth(double boardWidth) =>
      boardWidth - _ramWidth - editorWidth(boardWidth) - 2 * _gap;

  @override
  Widget build(BuildContext context) {
    final info = StepInfo.of(cpu);
    final halted = cpu.halted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopBar(
            mode: cpu.mode,
            onModeChanged: onModeChanged,
            detailed: detailedView,
            onDetailedChanged: onDetailedViewChanged,
            onAbout: () => showAboutGlassBox(context),
            clockHigh: clockHigh,
            isRunning: isRunning,
            halted: halted,
            speed: clockSpeed,
            onSpeedChanged: onClockSpeedChanged,
            onStepBack: onStepBack,
            onStep: halted ? null : onClockSingleStep,
            onInstructionStep: halted ? null : onClockInstructionStep,
            onRunToggle: halted && !isRunning ? null : onClockToggle,
            onRunToCursor: onRunToCursor,
            onReset: onReset,
            onLangChanged: onLangChanged,
          ),
          const SizedBox(height: 12),
          NarrationStrip(
            cpu: cpu,
            info: info,
            assembly: assembly,
            detailed: detailedView,
          ),
          const SizedBox(height: _gap),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: _ramWidth,
                    child: RamPanel(
                      cpu: cpu,
                      assembly: assembly,
                      onEdit: onRamEdit,
                    ),
                  ),
                  const SizedBox(width: _gap),
                  Expanded(child: _centre(constraints.maxWidth, info)),
                  const SizedBox(width: _gap),
                  SizedBox(
                    width: editorWidth(constraints.maxWidth),
                    child: ProgramEditor(
                      onAssemble: onAssemble,
                      currentAddress: highlightAddress,
                      onBreakpointsChanged: onBreakpointsChanged,
                      onCursorAddressChanged: onCursorAddressChanged,
                      mode: cpu.mode,
                      onModeChanged: onModeChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Datapath, devices and microcode. On wide boards the devices move to
  /// a column of their own, so the LCD, matrix and keypad stay in view.
  Widget _centre(double boardWidth, StepInfo info) {
    final extended = cpu.mode == CpuMode.extended;
    final devicesBeside =
        extended && centreWidth(boardWidth) >= _devicesColumnFrom;
    final devices = DevicesPanel(
      cpu: cpu,
      onKey: onKeypadKey,
      hardware: hardware,
    );
    // At least as tall as the window allows: height to spare goes to the
    // datapath, whose cards grow a little.
    final main = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Datapath(
                    cpu: cpu,
                    info: info,
                    assembly: assembly,
                    outputs: outputs,
                  ),
                ),
                if (extended && !devicesBeside) ...[
                  const SizedBox(height: _gap),
                  devices,
                ],
                if (detailedView) ...[
                  const SizedBox(height: _gap),
                  MicrocodePanel(cpu: cpu),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (!devicesBeside) return main;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: main),
        const SizedBox(width: _gap),
        SizedBox(
          width: _devicesWidth,
          child: SingleChildScrollView(child: devices),
        ),
      ],
    );
  }
}
