import '../core/io/bridge/hardware_bridge.dart';
import 'serial_ports_stub.dart'
    if (dart.library.ffi) 'serial_ports_desktop.dart'
    if (dart.library.js_interop) 'serial_ports_web.dart'
    as impl;

/// A serial port a board may be plugged into.
class SerialPortChoice {
  const SerialPortChoice(this.name, this.label);

  /// System name, e.g. `/dev/ttyUSB0` or `COM3`.
  final String name;

  /// What the user sees, e.g. `/dev/ttyUSB0 · CP2102 USB to UART`.
  final String label;
}

/// USB serial access on this platform: libserialport on desktop, Web
/// Serial in Chrome and Edge.
abstract class SerialPorts {
  /// The one for this build.
  static final SerialPorts instance = impl.create();

  /// Speed the firmware listens at.
  static const int defaultBaud = 115200;

  /// Whether USB serial works here at all.
  bool get supported;

  /// Why [supported] is false, to show the user.
  String get unsupportedReason;

  /// True on the web: the browser shows its own port picker, so ports
  /// cannot be listed in advance.
  bool get usesBrowserPicker;

  /// Ports present now (empty with a browser picker).
  List<SerialPortChoice> list();

  /// A link to the port named [name] (desktop), or to the port the user
  /// picks in the browser's dialog (web, [name] ignored). Returns null if
  /// the user cancels the dialog.
  Future<HardwareLink?> link(String? name, {int baud = defaultBaud});
}
