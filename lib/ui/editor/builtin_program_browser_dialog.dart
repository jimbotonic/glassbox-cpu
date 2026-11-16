import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../core/builtin_program_list.dart';
import '../../core/cpu_mode.dart';
import '../board/glass_widgets.dart';
import '../theme/glass.dart';

class BuiltinProgramBrowserDialog extends StatelessWidget {
  final List<BuiltinProgram> programs;
  final List<BuiltinProgramCategory> categories;
  final Function(BuiltinProgram program) onProgramSelected;

  /// Machine the CPU is in; programs for the other one are marked.
  final CpuMode currentMode;

  const BuiltinProgramBrowserDialog({
    super.key,
    required this.programs,
    required this.categories,
    required this.onProgramSelected,
    this.currentMode = CpuMode.classic,
  });

  @override
  Widget build(BuildContext context) {
    return GlassDialogFrame(
      title: 'BUILT-IN PROGRAMS',
      note:
          'Opens a program in the editor. A program for the other CPU '
          'switches the machine.',
      width: 520,
      maxHeight: 640,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final category in categories) ...[
            if (category != categories.first) const SizedBox(height: 10),
            GlassSectionTitle(category.name),
            for (final program in programs.where((p) => p.category == category))
              _ProgramTile(
                program: program,
                switchesMode: program.mode != currentMode,
                onTap: () {
                  onProgramSelected(program);
                  Navigator.pop(context);
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _ProgramTile extends StatelessWidget {
  final BuiltinProgram program;
  final VoidCallback onTap;

  /// Opening the program switches the CPU to its machine.
  final bool switchesMode;

  const _ProgramTile({
    required this.program,
    required this.onTap,
    required this.switchesMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Glass.raised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Glass.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.name,
                          style: const TextStyle(
                            color: Glass.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          program.description,
                          style: Glass.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (switchesMode)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Glass.busBorder),
                        color: Glass.busGround,
                      ),
                      child: Text(
                        'switches to ${program.mode.label}',
                        style: const TextStyle(fontSize: 11, color: Glass.bus),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(
                    FluentIcons.chevron_right_24_regular,
                    size: 16,
                    color: Glass.dim,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
