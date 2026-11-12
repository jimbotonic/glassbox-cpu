import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../core/cpu_mode.dart';
import '../theme/glass.dart';
import 'glass_widgets.dart';

/// Two rows: identity and how the board is shown, then execution.
class TopBar extends StatelessWidget {
  final CpuMode mode;
  final ValueChanged<CpuMode> onModeChanged;
  final bool detailed;
  final ValueChanged<bool> onDetailedChanged;
  final VoidCallback onAbout;

  final bool clockHigh;
  final bool isRunning;
  final bool halted;
  final double speed;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback? onStepBack;
  final VoidCallback? onStep;
  final VoidCallback? onInstructionStep;
  final VoidCallback? onRunToggle;
  final VoidCallback? onRunToCursor;
  final VoidCallback onReset;

  const TopBar({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.detailed,
    required this.onDetailedChanged,
    required this.onAbout,
    required this.clockHigh,
    required this.isRunning,
    required this.halted,
    required this.speed,
    required this.onSpeedChanged,
    required this.onStepBack,
    required this.onStep,
    required this.onInstructionStep,
    required this.onRunToggle,
    required this.onRunToCursor,
    required this.onReset,
  });

  /// Selectable clock speeds in Hz, on a 1-2-5 log scale.
  static const List<double> speeds = [
    0.25, 0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, //
  ];

  /// Index into [speeds] closest to [hz], measured on a log scale.
  static int speedIndex(double hz) {
    int best = 0;
    for (int i = 1; i < speeds.length; i++) {
      if ((math.log(speeds[i]) - math.log(hz)).abs() <
          (math.log(speeds[best]) - math.log(hz)).abs()) {
        best = i;
      }
    }
    return best;
  }

  static String formatSpeed(double hz) {
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(0)} kHz';
    if (hz < 1) return '$hz Hz';
    return '${hz.toStringAsFixed(0)} Hz';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Glass.panel,
        borderRadius: BorderRadius.circular(Glass.radius),
        border: Border.all(color: Glass.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'GlassBox CPU',
                style: TextStyle(
                  color: Glass.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              const Text('every signal visible', style: Glass.note),
              const Spacer(),
              Tooltip(
                message:
                    'Classic: ${CpuMode.classic.description}\n'
                    'Extended: ${CpuMode.extended.description}\n'
                    'Switching clears RAM.',
                child: GlassSegmented<CpuMode>(
                  semanticLabel: 'Machine',
                  options: const [
                    (CpuMode.classic, 'Classic', '16 B'),
                    (CpuMode.extended, 'Extended', '256 B'),
                  ],
                  value: mode,
                  onChanged: onModeChanged,
                  selectedFill: const Color(0xFF22303F),
                  selectedText: Glass.driveChip,
                ),
              ),
              const SizedBox(width: 12),
              GlassSegmented<bool>(
                semanticLabel: 'View',
                options: const [
                  (false, 'Simple', null),
                  (true, 'Detailed', null),
                ],
                value: detailed,
                onChanged: onDetailedChanged,
              ),
              const SizedBox(width: 8),
              GlassButton(
                icon: FluentIcons.info_24_regular,
                tooltip: 'About GlassBox CPU',
                onPressed: onAbout,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Glass.borderSoft),
          const SizedBox(height: 10),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  GlassButton(
                    icon: FluentIcons.arrow_previous_24_regular,
                    tooltip: 'Step back: undo the last step',
                    onPressed: onStepBack,
                  ),
                  GlassButton(
                    label: 'Step',
                    detail: 'cycle',
                    tooltip: 'One clock cycle (micro-step)',
                    onPressed: onStep,
                  ),
                  GlassButton(
                    label: 'Step',
                    detail: 'instruction',
                    tooltip: 'Run the rest of the current instruction',
                    onPressed: onInstructionStep,
                  ),
                  GlassButton(
                    label: isRunning ? 'Pause' : 'Run',
                    icon: isRunning
                        ? FluentIcons.pause_24_filled
                        : FluentIcons.play_24_filled,
                    primary: true,
                    tooltip: 'Run until a breakpoint or HLT',
                    onPressed: onRunToggle,
                  ),
                  GlassButton(
                    label: 'Run to cursor',
                    tooltip:
                        'Run until the instruction on the editor cursor line',
                    onPressed: onRunToCursor,
                  ),
                  GlassButton(
                    label: 'Reset',
                    tooltip: 'Restart the loaded program',
                    onPressed: onReset,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: halted
                        ? 'Halted'
                        : 'Clock ${clockHigh ? 'high' : 'low'}',
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: clockHigh ? Glass.led : const Color(0xFF3A2020),
                        boxShadow: clockHigh
                            ? [
                                BoxShadow(
                                  color: Glass.led.withValues(alpha: 0.7),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Clock', style: Glass.note),
                  SizedBox(
                    width: 180,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Glass.drive,
                        inactiveTrackColor: Glass.border,
                        thumbColor: Glass.driveText,
                        overlayColor: Glass.drive.withValues(alpha: 0.15),
                        trackHeight: 3,
                        tickMarkShape: SliderTickMarkShape.noTickMark,
                      ),
                      child: Slider(
                        value: speedIndex(speed).toDouble(),
                        max: (speeds.length - 1).toDouble(),
                        divisions: speeds.length - 1,
                        label: formatSpeed(speed),
                        semanticFormatterCallback: (v) =>
                            formatSpeed(speeds[v.round()]),
                        onChanged: (v) => onSpeedChanged(speeds[v.round()]),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      formatSpeed(speed),
                      style: const TextStyle(
                        fontFamily: Glass.mono,
                        fontSize: 13,
                        color: Glass.text,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
