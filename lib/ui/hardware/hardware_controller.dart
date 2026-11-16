import 'package:flutter/foundation.dart';

import '../../core/cpu.dart';
import '../../core/io/bridge/hardware_bridge.dart';
import '../../hardware/serial_ports.dart';
import '../../hardware/websocket_link.dart';

enum HardwareLinkKind { serial, wifi }

/// The bridge to a real board, plus the connection settings the dialog
/// remembers between openings. Notifies on every bridge change.
class HardwareController extends ChangeNotifier {
  HardwareController(Cpu cpu) {
    bridge = HardwareBridge(cpu, onChange: notifyListeners);
  }

  late final HardwareBridge bridge;

  HardwareLinkKind kind = HardwareLinkKind.serial;
  String? serialPort;
  int baud = SerialPorts.defaultBaud;
  String address = '';

  bool get connected => bridge.status == BridgeStatus.connected;
  bool get busy => bridge.status == BridgeStatus.connecting;

  /// Connects with the current settings. Returns false if the user
  /// cancelled the browser's port picker; throws on failure.
  Future<bool> connect() async {
    final HardwareLink? link = switch (kind) {
      HardwareLinkKind.serial => await SerialPorts.instance.link(
        serialPort,
        baud: baud,
      ),
      HardwareLinkKind.wifi => WebSocketLink.parse(address),
    };
    if (link == null) return false;
    await bridge.connect(link);
    return true;
  }

  Future<void> disconnect() => bridge.disconnect();

  @override
  void dispose() {
    bridge.disconnect();
    super.dispose();
  }
}
