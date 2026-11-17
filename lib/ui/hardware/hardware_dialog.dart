import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/io/bridge/hardware_bridge.dart';
import '../../hardware/serial_ports.dart';
import '../../l10n/board_strings.dart';
import '../board/glass_widgets.dart';
import '../theme/glass.dart';
import 'hardware_controller.dart';

/// Opens the connection dialog for real hardware.
Future<void> showHardwareDialog(
  BuildContext context,
  HardwareController controller,
) => showGlassDialog(context, child: HardwareDialog(controller: controller));

class HardwareDialog extends StatefulWidget {
  final HardwareController controller;

  const HardwareDialog({super.key, required this.controller});

  @override
  State<HardwareDialog> createState() => _HardwareDialogState();
}

class _HardwareDialogState extends State<HardwareDialog> {
  late final TextEditingController _address = TextEditingController(
    text: widget.controller.address,
  );
  List<SerialPortChoice> _ports = const [];
  String? _problem;

  HardwareController get c => widget.controller;
  SerialPorts get serial => SerialPorts.instance;

  @override
  void initState() {
    super.initState();
    if (!serial.supported) c.kind = HardwareLinkKind.wifi;
    _refreshPorts();
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  void _refreshPorts() {
    if (!serial.supported || serial.usesBrowserPicker) return;
    setState(() {
      _ports = serial.list();
      if (!_ports.any((p) => p.name == c.serialPort)) {
        c.serialPort = _ports.isEmpty ? null : _ports.first.name;
      }
    });
  }

  Future<void> _connect() async {
    c.address = _address.text;
    setState(() => _problem = null);
    try {
      await c.connect();
    } catch (e) {
      if (mounted) setState(() => _problem = c.bridge.error ?? '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final bridge = c.bridge;
        final locked = c.connected || c.busy;
        final t = tBoard;
        return GlassDialogFrame(
          title: t.realHardwareTitle,
          note: t.hardwareNote,
          width: 560,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusBanner(controller: c),
              const SizedBox(height: 16),
              IgnorePointer(
                ignoring: locked,
                child: Opacity(
                  opacity: locked ? 0.5 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassSegmented<HardwareLinkKind>(
                        semanticLabel: t.connection,
                        options: [
                          (HardwareLinkKind.serial, t.usbSerial, null),
                          (HardwareLinkKind.wifi, t.wifi, null),
                        ],
                        value: c.kind,
                        onChanged: (k) => setState(() => c.kind = k),
                      ),
                      const SizedBox(height: 14),
                      if (c.kind == HardwareLinkKind.serial)
                        _serialSettings()
                      else
                        _wifiSettings(),
                    ],
                  ),
                ),
              ),
              if (_problem != null) ...[
                const SizedBox(height: 12),
                Text(
                  _problem!,
                  style: const TextStyle(color: Glass.led, fontSize: 12),
                ),
              ],
              if (bridge.log.isNotEmpty) ...[
                const SizedBox(height: 16),
                GlassSectionTitle(t.log),
                const SizedBox(height: 6),
                _LogView(lines: bridge.log),
              ],
            ],
          ),
          actions: [
            if (c.connected) ...[
              GlassButton(
                label: t.resendState,
                tooltip: t.resendTooltip,
                onPressed: bridge.resync,
              ),
              GlassButton(label: t.disconnect, onPressed: c.disconnect),
            ] else
              GlassButton(
                label: c.busy ? t.connecting : t.connect,
                primary: true,
                onPressed: c.busy || !_canConnect ? null : _connect,
              ),
            GlassButton(
              label: t.close,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  bool get _canConnect => switch (c.kind) {
    HardwareLinkKind.serial =>
      serial.supported && (serial.usesBrowserPicker || c.serialPort != null),
    HardwareLinkKind.wifi => true,
  };

  Widget _serialSettings() {
    if (!serial.supported) {
      return _Hint(serial.unsupportedReason, warning: true);
    }
    final t = tBoard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (serial.usesBrowserPicker)
          _Hint(t.browserPickerHint)
        else
          Row(
            children: [
              Expanded(
                child: _Dropdown<String>(
                  label: t.portLabel,
                  value: c.serialPort,
                  items: [for (final p in _ports) (p.name, p.label)],
                  empty: t.noSerialPort,
                  onChanged: (v) => setState(() => c.serialPort = v),
                ),
              ),
              const SizedBox(width: 8),
              GlassButton(
                label: t.refresh,
                tooltip: t.refreshTooltip,
                onPressed: _refreshPorts,
              ),
            ],
          ),
        const SizedBox(height: 10),
        _Dropdown<int>(
          label: t.speed,
          value: c.baud,
          items: [
            (115200, t.baud(115200, true)),
            (57600, t.baud(57600, false)),
            (9600, t.baud(9600, false)),
          ],
          onChanged: (v) => setState(() => c.baud = v ?? c.baud),
        ),
      ],
    );
  }

  Widget _wifiSettings() {
    final mixedContent =
        kIsWeb &&
        Uri.base.scheme == 'https' &&
        !_address.text.trim().startsWith('wss://');
    final t = tBoard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _address,
          style: const TextStyle(
            fontFamily: Glass.mono,
            fontSize: 14,
            color: Glass.text,
          ),
          cursorColor: Glass.bus,
          decoration: InputDecoration(
            labelText: t.boardAddress,
            labelStyle: const TextStyle(color: Glass.muted, fontSize: 13),
            floatingLabelStyle: const TextStyle(color: Glass.driveText),
            hintText: '192.168.1.50:81',
            hintStyle: const TextStyle(color: Glass.faint),
            filled: true,
            fillColor: Glass.ground,
            enabledBorder: _border(Glass.border),
            focusedBorder: _border(Glass.drive, 2),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _connect(),
        ),
        const SizedBox(height: 8),
        _Hint(t.addressHint),
        if (mixedContent) ...[
          const SizedBox(height: 6),
          _Hint(t.mixedContent, warning: true),
        ],
      ],
    );
  }

  static OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Glass.radius),
        borderSide: BorderSide(color: color, width: width),
      );
}

class _StatusBanner extends StatelessWidget {
  final HardwareController controller;

  const _StatusBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    final bridge = controller.bridge;
    final t = tBoard;
    final (dot, title, detail) = switch (bridge.status) {
      BridgeStatus.connected => (
        Glass.ok,
        t.connectedTo(bridge.board!.board),
        '${bridge.link!.description} · '
            '${bridge.board!.parts.isEmpty ? t.noPartsReported : bridge.board!.parts.map((p) => p.label).join(', ')}',
      ),
      BridgeStatus.connecting => (
        Glass.bus,
        t.connecting,
        bridge.link?.description ?? '',
      ),
      BridgeStatus.disconnected => (
        Glass.faint,
        t.notConnected,
        t.worksWithoutBoard,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Glass.sunken,
        borderRadius: BorderRadius.circular(Glass.radius),
        border: Border.all(color: Glass.border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Glass.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(detail, style: Glass.note),
              ],
            ),
          ),
          if (bridge.status == BridgeStatus.connected)
            Text(
              bridge.queued + bridge.inFlight == 0
                  ? t.inStep
                  : t.toSend(bridge.queued + bridge.inFlight),
              style: Glass.code.copyWith(fontSize: 11, color: Glass.muted),
            ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<(T, String)> items;
  final String? empty;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.empty,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _Hint(empty ?? tBoard.nothingToChoose, warning: true);
    }
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Glass.muted, fontSize: 13),
        filled: true,
        fillColor: Glass.ground,
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Glass.radius),
          borderSide: const BorderSide(color: Glass.border),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: Glass.raised,
          iconEnabledColor: Glass.muted,
          style: const TextStyle(
            fontFamily: Glass.mono,
            fontSize: 13,
            color: Glass.text,
          ),
          items: [
            for (final (v, text) in items)
              DropdownMenuItem(
                value: v,
                child: Text(text, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  final bool warning;

  const _Hint(this.text, {this.warning = false});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      height: 1.4,
      color: warning ? Glass.bus : Glass.muted,
    ),
  );
}

class _LogView extends StatelessWidget {
  final List<String> lines;

  const _LogView({required this.lines});

  @override
  Widget build(BuildContext context) {
    final shown = lines.length > 8 ? lines.sublist(lines.length - 8) : lines;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Glass.ground,
        borderRadius: BorderRadius.circular(Glass.radius),
        border: Border.all(color: Glass.borderSoft),
      ),
      child: SelectableText(
        shown.join('\n'),
        style: Glass.code.copyWith(
          fontSize: 11,
          height: 1.5,
          color: Glass.textSoft,
        ),
      ),
    );
  }
}
