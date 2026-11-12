import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import 'core/control_word.dart';
import 'core/cpu.dart';
import 'core/cpu_mode.dart';
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
import 'ui/modules/stack_pointer_module.dart';
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

  /// Switches between the Classic and Extended machines.
  final ValueChanged<CpuMode> onModeChanged;

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
    required this.onModeChanged,
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

  // Third column: as wide as the microcode panel.
  static const double _columnWidth = 400;
  static const double _sideWidth = 136; // beside the 250 px output panel
  static const double _halfWidth = 193; // A and B side by side

  Widget _node(BusNode node, Widget child) =>
      KeyedSubtree(key: _nodeKeys[node], child: child);

  @override
  Widget build(BuildContext context) {
    const spaceBetweenModules = 14.0;
    final int word = cpu.controlWord;
    bool on(ControlWord signal) => signal.isActive(word);
    final info = StepInfo.of(cpu);
    final bus = cpu.bus;
    final mode = cpu.mode;
    final extended = mode == CpuMode.extended;

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
                            bitWidth: mode.addressBits,
                            note: '(${mode.addressBits}-bit)',
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
                            mode: mode,
                            programCounter: extended
                                ? cpu.programCounter
                                : null,
                            stackPointer: extended ? cpu.stackPointer : null,
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
                            bitWidth: mode.addressBits,
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
                            mode: mode,
                            operand: extended ? cpu.currentOperand : null,
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
                            operation: StepInfo.aluLabel(word),
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
                        // Every row spans the microcode panel's 400 px:
                        // 250 + 14 + 136, then 193 + 14 + 193.
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              SizedBox(
                                width: _sideWidth,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: FlagsModule(
                                        carryFlag: cpu.carryFlag,
                                        zeroFlag: cpu.zeroFlag,
                                        isInput: on(ControlWord.fi),
                                      ),
                                    ),
                                    if (extended) ...[
                                      const SizedBox(
                                        height: spaceBetweenModules,
                                      ),
                                      _node(
                                        BusNode.stackPointer,
                                        StackPointerModule(
                                          value: cpu.stackPointer,
                                          ram: cpu.ram,
                                          isOutput: on(ControlWord.spo),
                                          isIncrement: on(ControlWord.spInc),
                                          isDecrement: on(ControlWord.spDec),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: spaceBetweenModules),
                        Row(
                          children: [
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
                                width: _halfWidth,
                              ),
                            ),
                            const SizedBox(width: spaceBetweenModules),
                            _node(
                              BusNode.registerB,
                              RegisterModule(
                                name: 'B Register',
                                value: cpu.registerB,
                                busValue: bus,
                                isInput: on(ControlWord.bi),
                                isOutput: on(ControlWord.bo),
                                color: Colors.red,
                                isConnectedToBus: true,
                                width: _halfWidth,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: spaceBetweenModules),
                        StepCaptionModule(
                          info: info,
                          detailed: detailedView,
                          width: _columnWidth,
                        ),
                      ],
                    ),
                    const SizedBox(width: spaceBetweenModules),
                    ProgramEditor(
                      initialProgram: initialProgram,
                      mode: mode,
                      onModeChanged: onModeChanged,
                      currentAddress: highlightAddress,
                      onBreakpointsChanged: onBreakpointsChanged,
                      onCursorAddressChanged: onCursorAddressChanged,
                      onAssemble: (program, hasError) {
                        if (!hasError && program.isNotEmpty) {
                          onLoadProgram(program);
                        }
                      },
                      headerActions: [
                        _ModeToggle(mode: mode, onChanged: onModeChanged),
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

/// Header chip that shows the current machine and switches to the other.
class _ModeToggle extends StatelessWidget {
  final CpuMode mode;
  final ValueChanged<CpuMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final other = mode == CpuMode.classic ? CpuMode.extended : CpuMode.classic;
    final color = mode == CpuMode.classic ? Colors.blue : Colors.cyanAccent;
    return Tooltip(
      message:
          '${mode.label} CPU: ${mode.description}\n'
          'Click to switch to ${other.label} (${other.description}). '
          'RAM is cleared.',
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => onChanged(other),
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.6)),
            color: color.withValues(alpha: 0.12),
          ),
          child: Text(
            mode.label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
