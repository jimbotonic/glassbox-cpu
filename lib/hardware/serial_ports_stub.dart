import '../core/io/bridge/hardware_bridge.dart';
import 'serial_ports.dart';

SerialPorts create() => _Unsupported();

class _Unsupported extends SerialPorts {
  @override
  bool get supported => false;

  @override
  String get unsupportedReason =>
      'USB serial is not available on this platform.';

  @override
  bool get usesBrowserPicker => false;

  @override
  List<SerialPortChoice> list() => const [];

  @override
  Future<HardwareLink?> link(
    String? name, {
    int baud = SerialPorts.defaultBaud,
  }) => throw UnsupportedError(unsupportedReason);
}
