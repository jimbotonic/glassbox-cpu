import 'keypad.dart';
import 'led_matrix.dart';
import 'text_lcd.dart';

/// A device on the I/O bus, answering one or more numbered ports.
///
/// The CPU only knows `OUT port` (the device at that port reads the bus,
/// signal DI) and `IN port` (the device drives the bus, signal DO); what a
/// write or read means is up to the device.
abstract class IoDevice {
  /// Short name, e.g. `Text LCD`.
  String get name;

  /// Absolute port numbers this device answers.
  List<int> get ports;

  /// What [port] does on this device, e.g. `LCD data`.
  String portName(int port);

  /// The CPU writes [value] to [port] (OUT).
  void write(int port, int value);

  /// The CPU reads [port] (IN). May have side effects, such as a keypad
  /// forgetting the key once it has been read.
  int read(int port);

  /// What [read] would return, without its side effects; for the UI.
  int peek(int port) => read(port);

  /// Back to the power-on state.
  void reset();

  /// Copy of the device state, for step-back. Must not share mutable data
  /// with the device.
  Object? save();

  /// Puts back a state returned by [save].
  void restore(Object? state);

  /// Port writes that bring a device fresh from [reset] to the current
  /// state, as `(port, value)` pairs. A hardware bridge sends them to put a
  /// real device back in step after a reset, a step-back or a reconnect.
  /// Input-only devices have nothing to replay.
  List<(int, int)> replay() => const [];
}

/// Called after every port write, port 0 included; a serial bridge can
/// mirror these writes to real hardware.
typedef PortWriteListener = void Function(int port, int value);

/// Called after the devices jumped to another state ([IoPorts.reset] or
/// [IoPorts.restore]) rather than changing through port writes.
typedef PortStateListener = void Function();

/// Routes port numbers to devices.
///
/// Port 0 is the output register (the 7-segment display) and is handled by
/// the CPU itself; [write] still reports it to listeners.
class IoPorts {
  IoPorts(List<IoDevice> devices) : devices = List.unmodifiable(devices) {
    for (final device in this.devices) {
      for (final port in device.ports) {
        if (port == 0 || _byPort.containsKey(port)) {
          throw ArgumentError('Port $port is already taken');
        }
        _byPort[port] = device;
      }
    }
  }

  /// The devices of the Extended CPU: LCD on ports 1-2, LED matrix on
  /// ports 3-4, keypad on port 5.
  factory IoPorts.standard() => IoPorts([
    TextLcd(commandPort: 1, dataPort: 2),
    LedMatrix(rowPort: 3, dataPort: 4),
    Keypad(port: 5),
  ]);

  /// Port of the output register (the 7-segment display).
  static const int displayPort = 0;

  final List<IoDevice> devices;
  final Map<int, IoDevice> _byPort = {};
  final List<PortWriteListener> _listeners = [];
  final List<PortStateListener> _stateListeners = [];

  /// Device answering [port], or null (port 0, or nothing connected).
  IoDevice? deviceAt(int port) => _byPort[port & 0xFF];

  /// The first device of type [T], or null.
  T? device<T extends IoDevice>() {
    for (final d in devices) {
      if (d is T) return d;
    }
    return null;
  }

  /// What [port] is for, e.g. `display` or `LCD data`.
  String portName(int port) {
    if (port == displayPort) return 'display';
    return deviceAt(port)?.portName(port & 0xFF) ?? 'nothing connected';
  }

  void addListener(PortWriteListener listener) => _listeners.add(listener);
  void removeListener(PortWriteListener listener) =>
      _listeners.remove(listener);

  void addStateListener(PortStateListener listener) =>
      _stateListeners.add(listener);
  void removeStateListener(PortStateListener listener) =>
      _stateListeners.remove(listener);

  void _stateChanged() {
    for (final listener in List.of(_stateListeners)) {
      listener();
    }
  }

  /// Hands [value] to the device at [port], then tells the listeners.
  void write(int port, int value) {
    port &= 0xFF;
    value &= 0xFF;
    deviceAt(port)?.write(port, value);
    for (final listener in List.of(_listeners)) {
      listener(port, value);
    }
  }

  /// Value the device at [port] drives onto the bus. An unconnected port
  /// drives nothing; it reads as 0 here.
  int read(int port) => (deviceAt(port)?.read(port & 0xFF) ?? 0) & 0xFF;

  /// [read] without side effects.
  int peek(int port) => (deviceAt(port)?.peek(port & 0xFF) ?? 0) & 0xFF;

  void reset() {
    for (final d in devices) {
      d.reset();
    }
    _stateChanged();
  }

  /// States of all devices, for step-back.
  List<Object?> save() =>
      List.unmodifiable([for (final d in devices) d.save()]);

  void restore(List<Object?> states) {
    for (int i = 0; i < devices.length; i++) {
      devices[i].restore(states[i]);
    }
    _stateChanged();
  }

  /// Port writes rebuilding every device's state from power-on.
  List<(int, int)> replay() => [for (final d in devices) ...d.replay()];
}
