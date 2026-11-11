import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import 'core/control_word.dart';
import 'core/cpu.dart';
import 'core/step_info.dart';
import 'ui/about_dialog.dart';
import 'ui/editor/code_editor.dart';
import 'ui/modules/alu_module.dart';
import 'ui/modules/bus_module.dart';
import 'ui/modules/clock_module.dart';
import 'ui/modules/flags_module.dart';
import 'ui/modules/instruction_register_module.dart';
import 'ui/modules/microcode_module.dart';
import 'ui/modules/output_module.dart';
import 'ui/modules/program_counter_module.dart';
import 'ui/modules/ram_module.dart';
import 'ui/modules/register_module.dart';
import 'ui/modules/step_caption_module.dart';
import 'ui/painters/bus_arrow_painter.dart';
import 'ui/painters/grid_painter.dart';

/// Lays out the board's modules around the [Cpu] state and draws the bus
/// transfer of the last step as an arrow over them.
class CPULayout extends StatelessWidget {
  final Cpu cpu;
  final String? initialProgram;

  // Clock
  final bool clockHigh;
  final bool isRunning;
  final double clockSpeed;
  final bool manualMode;

  // View
  final bool detailedView;
  final Animation<double> busAnimation;

  /// RAM address whose source line the editor highlights.
  final int highlightAddress;

  // Clock controls
  final VoidCallback onClockToggle;
  final VoidCallback onClockSingleStep;
  final VoidCallback onClockInstructionStep;
  final VoidCallback? onStepBack;
  final VoidCallback? onRunToCursor;
  final ValueChanged<double> onClockSpeedChanged;
  final ValueChanged<bool> onClockManualModeChanged;
  final VoidCallback onReset;

  // View controls
  final ValueChanged<bool> onDetailedViewChanged;

  // Program
  final void Function(int address, int value) onRamEdit;
  final void Function(List<int> program) onLoadProgram;
  final ValueChanged<Set<int>> onBreakpointsChanged;
  final ValueChanged<int?> onCursorAddressChanged;

  const CPULayout({
    super.key,
    required this.cpu,
    this.initialProgram,
    required this.clockHigh,
    required this.isRunning,
    required this.clockSpeed,
    required this.manualMode,
    required this.detailedView,
    required this.busAnimation,
    required this.highlightAddress,
    required this.onClockToggle,
    required this.onClockSingleStep,
    required this.onClockInstructionStep,
    required this.onStepBack,
    required this.onRunToCursor,
    required this.onClockSpeedChanged,
    required this.onClockManualModeChanged,
    required this.onReset,
    required this.onDetailedViewChanged,
    required this.onRamEdit,
    required this.onLoadProgram,
    required this.onBreakpointsChanged,
    required this.onCursorAddressChanged,
  });

  // Keys locate the modules for the bus arrows. There is one board, so
  // static keys are safe.
  static final GlobalKey _boardKey = GlobalKey();
  static final Map<BusNode, GlobalKey> _nodeKeys = {
    for (final node in BusNode.values) node: GlobalKey(),
  };

  Widget _node(BusNode node, Widget child) =>
      KeyedSubtree(key: _nodeKeys[node], child: child);

  @override
  Widget build(BuildContext context) {
    const spaceBetweenModules = 14.0;
    final int word = cpu.controlWord;
    bool on(ControlWord signal) => signal.isActive(word);
    final info = StepInfo.of(cpu);
    final bus = cpu.bus;

    return Stack(
      key: _boardKey,
      children: [
        Positioned.fill(child: CustomPaint(painter: GridPainter())),
        Positioned.fill(
          child: Center(
            // The Column gives the Row unbounded height, so every module
            // keeps its natural height and the board stays centred.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        _node(
                          BusNode.memoryAddress,
                          RegisterModule(
                            name: 'MEMORY ADDRESS REGISTER',
                            value: cpu.memoryAddressRegister,
                            busValue: bus,
                            isInput: on(ControlWord.mi),
                            isOutput: false,
                            color: Colors.red,
                            isConnectedToBus: true,
                            bitWidth: 4,
                          ),
                        ),
                        const SizedBox(height: spaceBetweenModules),
                        _node(
                          BusNode.ram,
                          RAMModule(
                            ram: cpu.ram,
                            address: cpu.memoryAddressRegister,
                            busValue: bus,
                            isInput: on(ControlWord.ri),
                            isOutput: on(ControlWord.ro),
                            onEdit: onRamEdit,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: spaceBetweenModules),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _node(
                          BusNode.programCounter,
                          ProgramCounterModule(
                            value: cpu.programCounter,
                            busValue: bus,
                            isOutput: on(ControlWord.co),
                            isCount: on(ControlWord.ce),
                            isJump: on(ControlWord.j),
                          ),
                        ),
                        const SizedBox(height: spaceBetweenModules),
                        ClockModule(
                          clockHigh: clockHigh,
                          isRunning: isRunning,
                          speed: clockSpeed,
                          manualMode: manualMode,
                          onToggle: onClockToggle,
                          onStep: onClockSingleStep,
                          onInstructionStep: onClockInstructionStep,
                          onStepBack: onStepBack,
                          onRunToCursor: onRunToCursor,
                          onReset: onReset,
                          onSpeedChanged: onClockSpeedChanged,
                          onModeChanged: onClockManualModeChanged,
                        ),
                        const SizedBox(height: spaceBetweenModules),
                        _node(
                          BusNode.instructionRegister,
                          InstructionRegisterModule(
                            value: cpu.instructionRegister,
                            busValue: bus,
                            isInput: on(ControlWord.ii),
                            isOutput: on(ControlWord.io),
                          ),
                        ),
                        const SizedBox(height: spaceBetweenModules),
                        BusModule(
                          bus: bus,
                          busActive: cpu.busActive,
                          animation: busAnimation,
                        ),
                        const SizedBox(height: spaceBetweenModules),
                        _node(
                          BusNode.alu,
                          ALUModule(
                            registerA: cpu.registerA,
                            registerB: cpu.registerB,
                            sumRegister: cpu.sumRegister,
                            subtract: on(ControlWord.su),
                            carryFlag: cpu.carryFlag,
                            zeroFlag: cpu.zeroFlag,
                            isOutput: on(ControlWord.so),
                            isFlagsIn: on(ControlWord.fi),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: spaceBetweenModules),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (detailedView) ...[
                          MicrocodeModule(cpu: cpu),
                          const SizedBox(height: spaceBetweenModules),
                        ],
                        Row(
                          children: [
                            _node(
                              BusNode.output,
                              OutputModule(
                                value: cpu.outputRegister,
                                busValue: bus,
                                isInput: on(ControlWord.oi),
                              ),
                            ),
                            const SizedBox(width: spaceBetweenModules),
                            FlagsModule(
                              carryFlag: cpu.carryFlag,
                              zeroFlag: cpu.zeroFlag,
                              isInput: on(ControlWord.fi),
                            ),
                          ],
                        ),
                        const SizedBox(height: spaceBetweenModules),
                        _node(
                          BusNode.registerA,
                          RegisterModule(
                            name: 'A Register',
                            value: cpu.registerA,
                            busValue: bus,
                            isInput: on(ControlWord.ai),
                            isOutput: on(ControlWord.ao),
                            color: Colors.red,
                            isConnectedToBus: true,
                          ),
                        ),
                        const SizedBox(height: spaceBetweenModules),
                        _node(
                          BusNode.registerB,
                          RegisterModule(
                            name: 'B Register',
                            value: cpu.registerB,
                            busValue: bus,
                            isInput: on(ControlWord.bi),
                            isOutput: false,
                            color: Colors.red,
                            isConnectedToBus: true,
                          ),
                        ),
                        const SizedBox(height: spaceBetweenModules),
                        StepCaptionModule(info: info, detailed: detailedView),
                      ],
                    ),
                    const SizedBox(width: spaceBetweenModules),
                    ProgramEditor(
                      initialProgram: initialProgram,
                      currentAddress: highlightAddress,
                      onBreakpointsChanged: onBreakpointsChanged,
                      onCursorAddressChanged: onCursorAddressChanged,
                      onAssemble: (program, hasError) {
                        if (!hasError && program.isNotEmpty) {
                          onLoadProgram(program);
                        }
                      },
                      headerActions: [
                        _HeaderButton(
                          icon: detailedView
                              ? FluentIcons.eye_24_regular
                              : FluentIcons.eye_off_24_regular,
                          tooltip: detailedView
                              ? 'Detailed view: microcode shown (click for simple)'
                              : 'Simple view: microcode hidden (click for detailed)',
                          onPressed: () => onDetailedViewChanged(!detailedView),
                        ),
                        _HeaderButton(
                          icon: FluentIcons.info_24_regular,
                          tooltip: 'About',
                          onPressed: () => showAboutGlassBox(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: BusArrowPainter(
                originKey: _boardKey,
                nodeKeys: _nodeKeys,
                source: cpu.busActive ? info.source : null,
                destinations: info.destinations,
                label:
                    '0x${bus.toRadixString(16).toUpperCase().padLeft(2, '0')}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 16),
      color: Colors.blue,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
      onPressed: onPressed,
    );
  }
}
