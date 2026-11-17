import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

import '../core/io/bridge/hardware_bridge.dart';
import '../l10n/board_strings.dart';
import 'serial_ports.dart';

SerialPorts create() => _DesktopSerialPorts();

class _DesktopSerialPorts extends SerialPorts {
  bool get _desktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  @override
  bool get supported {
    if (!_desktop) return false;
    try {
      SerialPort.availablePorts; // loads the native library
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  String get unsupportedReason =>
      _desktop ? tBoard.serialLibraryMissing : tBoard.serialNeedsBuild;

  @override
  bool get usesBrowserPicker => false;

  @override
  List<SerialPortChoice> list() {
    final choices = <SerialPortChoice>[];
    for (final name in SerialPort.availablePorts) {
      String? about;
      final port = SerialPort(name);
      try {
        about = port.productName ?? port.description;
      } catch (_) {
      } finally {
        port.dispose();
      }
      choices.add(
        SerialPortChoice(
          name,
          about == null || about == name ? name : '$name · $about',
        ),
      );
    }
    return choices;
  }

  @override
  Future<HardwareLink?> link(
    String? name, {
    int baud = SerialPorts.defaultBaud,
  }) async {
    if (name == null) throw ArgumentError(tBoard.chooseSerialPort);
    return _DesktopSerialLink(name, baud);
  }
}

class _DesktopSerialLink implements HardwareLink {
  _DesktopSerialLink(this.name, this.baud);

  final String name;
  final int baud;
  SerialPort? _port;
  SerialPortReader? _reader;

  @override
  String get description => 'USB $name';

  /// 4 lines of at most 8 bytes stay under an Uno's 64-byte buffer.
  @override
  int get window => 4;

  @override
  Future<void> open() async {
    final port = SerialPort(name);
    if (!port.openReadWrite()) {
      final error = SerialPort.lastError;
      port.dispose();
      throw StateError(
        tBoard.cannotOpenPort(name, error?.message, Platform.isLinux),
      );
    }
    final config = SerialPortConfig()
      ..baudRate = baud
      ..bits = 8
      ..parity = SerialPortParity.none
      ..stopBits = 1;
    port.config = config;
    config.dispose();
    _port = port;
    _reader = SerialPortReader(port);
  }

  @override
  Stream<String> get received => _reader!.stream.map(latin1.decode);

  @override
  void send(String line) {
    final written = _port!.write(
      Uint8List.fromList(latin1.encode('$line\n')),
      timeout: 500,
    );
    if (written < 0) throw StateError(tBoard.writeFailed(name));
  }

  @override
  Future<void> close() async {
    _reader?.close();
    final port = _port;
    _port = null;
    _reader = null;
    if (port != null) {
      port.close();
      port.dispose();
    }
  }
}
