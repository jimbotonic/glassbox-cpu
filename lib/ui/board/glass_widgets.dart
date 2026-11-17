import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../l10n/board_strings.dart';
import '../theme/glass.dart';

/// Panel whose border and glow show its [role] on the bus. The size never
/// changes with the role, so nothing on the board moves between steps.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final BusRole role;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  const GlassPanel({
    super.key,
    required this.child,
    this.role = BusRole.idle,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 12),
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = switch (role) {
      BusRole.drive => Glass.drive,
      BusRole.read => Glass.read,
      _ => null,
    };
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Glass.panel,
        borderRadius: BorderRadius.circular(Glass.radius),
        border: Border.all(color: accent ?? borderColor ?? Glass.border),
        boxShadow: accent == null
            ? null
            : [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 18,
                ),
              ],
      ),
      child: child,
    );
  }
}

/// `DRIVES BUS ▸` / `◂ READS BUS` / `+1`, or [idle] text when idle.
class RoleLabel extends StatelessWidget {
  final BusRole role;
  final String idle;
  final String? countText;

  const RoleLabel({
    super.key,
    required this.role,
    this.idle = '',
    this.countText,
  });

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (role) {
      BusRole.drive => (tBoard.drivesBus, Glass.driveText),
      BusRole.read => (tBoard.readsBus, Glass.readText),
      BusRole.count => (countText ?? tBoard.counts, Glass.count),
      BusRole.idle => (idle, Glass.dim),
    };
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}

/// A row of bit LEDs, most significant first.
class LedRow extends StatelessWidget {
  final int value;
  final int bits;
  final double size;

  const LedRow({super.key, required this.value, this.bits = 8, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = bits - 1; i >= 0; i--)
          Container(
            width: size,
            height: size,
            margin: EdgeInsets.only(right: i == 0 ? 0 : 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (value >> i) & 1 == 1 ? Glass.led : Glass.ledOff,
              border: (value >> i) & 1 == 1
                  ? null
                  : Border.all(color: Glass.ledOffBorder),
              boxShadow: (value >> i) & 1 == 1
                  ? [
                      BoxShadow(
                        color: Glass.led.withValues(alpha: 0.7),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Signal mnemonic chip, coloured by what the signal does.
class SignalChip extends StatelessWidget {
  final String label;
  final BusRole role;
  final bool active;

  const SignalChip({
    super.key,
    required this.label,
    this.role = BusRole.idle,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final (fill, fg, outline) = !active
        ? (Glass.raised, Glass.dim, null)
        : switch (role) {
            BusRole.drive => (Glass.driveFill, Glass.driveChip, Glass.drive),
            BusRole.read => (Glass.readFill, Glass.readChip, Glass.read),
            _ => (const Color(0xFF3A3520), Glass.count, Glass.count),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(4),
        border: outline == null ? null : Border.all(color: outline),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: Glass.mono,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

/// Two-or-more option switch, e.g. Classic | Extended.
class GlassSegmented<T> extends StatelessWidget {
  final List<(T, String, String?)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String semanticLabel;
  final Color selectedFill;
  final Color selectedText;

  const GlassSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.selectedFill = Glass.border,
    this.selectedText = Glass.text,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Glass.ground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Glass.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (option, label, detail) in options)
              Semantics(
                selected: option == value,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: option == value ? null : () => onChanged(option),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: option == value ? selectedFill : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text.rich(
                      TextSpan(
                        text: label,
                        children: [
                          if (detail != null)
                            TextSpan(
                              text: ' $detail',
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                color: Glass.dim,
                              ),
                            ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: option == value ? selectedText : Glass.muted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Flat board button. [primary] is the filled blue Run button.
class GlassButton extends StatelessWidget {
  final String? label;
  final String? detail;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool primary;
  final Color? fill;
  final Color? foreground;
  final double height;

  const GlassButton({
    super.key,
    this.label,
    this.detail,
    this.icon,
    this.tooltip,
    required this.onPressed,
    this.primary = false,
    this.fill,
    this.foreground,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bg = fill ?? (primary ? Glass.drive : Glass.raised);
    final fg = foreground ?? (primary ? const Color(0xFF04101F) : Glass.text);
    final button = Material(
      color: enabled ? bg : Glass.raised.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: primary || fill != null
            ? BorderSide.none
            : const BorderSide(color: Glass.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          height: height,
          constraints: BoxConstraints(minWidth: height),
          padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 12),
          // widthFactor keeps the button as narrow as its content, but
          // still centres it when a parent forces a width.
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(icon, size: 17, color: enabled ? fg : Glass.faint),
                if (icon != null && label != null) const SizedBox(width: 6),
                if (label != null)
                  Text.rich(
                    TextSpan(
                      text: label,
                      children: [
                        if (detail != null)
                          TextSpan(
                            text: ' $detail',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: enabled ? Glass.dim : Glass.faint,
                            ),
                          ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
                      color: enabled ? fg : Glass.faint,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return tooltip == null
        ? button
        : Tooltip(
            message: tooltip!,
            waitDuration: const Duration(milliseconds: 500),
            child: button,
          );
  }
}

/// Opens [child] in a dialog styled like a board panel.
Future<T?> showGlassDialog<T>(BuildContext context, {required Widget child}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => Dialog(
      backgroundColor: Glass.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Glass.radius),
        side: const BorderSide(color: Glass.border),
      ),
      child: child,
    ),
  );
}

/// Layout shared by every dialog: a panel title (in capitals, as given,
/// so hex like `0x0F` keeps its case) with a note under it, a
/// close button, a scrolling [body] and optional [actions] at the bottom.
class GlassDialogFrame extends StatelessWidget {
  final String title;
  final String? note;
  final double width;
  final double? maxHeight;
  final Widget body;
  final List<Widget> actions;

  /// Whether [body] scrolls; turn off for short dialogs with a text field.
  final bool scrollable;

  const GlassDialogFrame({
    super.key,
    required this.title,
    this.note,
    this.width = 480,
    this.maxHeight,
    required this.body,
    this.actions = const [],
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Glass.dialogTitle),
                        if (note != null) ...[
                          const SizedBox(height: 4),
                          Text(note!, style: Glass.note),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GlassButton(
                  icon: FluentIcons.dismiss_24_regular,
                  tooltip: tBoard.close,
                  height: 36,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (scrollable)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: SingleChildScrollView(child: body),
                ),
              )
            else
              Padding(padding: const EdgeInsets.only(right: 4), child: body),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      actions[i],
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small caps heading inside a panel or dialog, e.g. `OPERAND TYPES`.
class GlassSectionTitle extends StatelessWidget {
  final String text;

  const GlassSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(), style: Glass.sectionTitle),
  );
}

/// Sunken box for code samples, in the editor's colours.
class GlassCodeBlock extends StatelessWidget {
  final String code;

  const GlassCodeBlock(this.code, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Glass.ground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Glass.borderSoft),
      ),
      child: Text.rich(
        _highlight(code),
        style: Glass.code.copyWith(height: 1.5),
      ),
    );
  }

  /// Comments in grey italics; the rest as plain code.
  static TextSpan _highlight(String code) {
    final lines = code.split('\n');
    return TextSpan(
      children: [
        for (int i = 0; i < lines.length; i++) ...[
          if (i > 0) const TextSpan(text: '\n'),
          ..._line(lines[i]),
        ],
      ],
    );
  }

  static List<TextSpan> _line(String line) {
    final comment = line.indexOf(';');
    if (comment < 0) return [TextSpan(text: line)];
    return [
      TextSpan(text: line.substring(0, comment)),
      TextSpan(
        text: line.substring(comment),
        style: const TextStyle(
          color: Glass.synComment,
          fontStyle: FontStyle.italic,
        ),
      ),
    ];
  }
}
