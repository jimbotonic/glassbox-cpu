import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../core/io/bridge/hardware_bridge.dart';
import '../l10n/board_strings.dart';
import 'serial_ports.dart';

SerialPorts create() => _WebSerialPorts();

// Web Serial is not in package:web yet; the bits used here.
extension type _Navigator(JSObject _) implements JSObject {
  external _Serial? get serial;
}

extension type _Serial(JSObject _) implements JSObject {
  external JSPromise<_Port> requestPort();
}

extension type _Port(JSObject _) implements JSObject {
  external JSPromise<JSAny?> open(_OpenOptions options);
  external JSPromise<JSAny?> close();
  external web.ReadableStream? get readable;
  external web.WritableStream? get writable;
  external _PortInfo getInfo();
}

extension type _PortInfo(JSObject _) implements JSObject {
  external int? get usbVendorId;
  external int? get usbProductId;
}

extension type _OpenOptions._(JSObject _) implements JSObject {
  external factory _OpenOptions({int baudRate});
}

class _WebSerialPorts extends SerialPorts {
  _Serial? get _serial => _Navigator(web.window.navigator).serial;

  @override
  bool get supported => _serial != null;

  @override
  String get unsupportedReason => tBoard.noWebSerial;

  @override
  bool get usesBrowserPicker => true;

  @override
  List<SerialPortChoice> list() => const [];

  @override
  Future<HardwareLink?> link(
    String? name, {
    int baud = SerialPorts.defaultBaud,
  }) async {
    final serial = _serial;
    if (serial == null) throw UnsupportedError(unsupportedReason);
    try {
      final port = await serial.requestPort().toDart;
      return _WebSerialLink(port, baud);
    } catch (e) {
      // NotFoundError: the user closed the picker without choosing.
      if ('$e'.contains('NotFoundError') || '$e'.contains('No port')) {
        return null;
      }
      rethrow;
    }
  }
}

class _WebSerialLink implements HardwareLink {
  _WebSerialLink(this._port, this.baud);

  final _Port _port;
  final int baud;
  web.ReadableStreamDefaultReader? _reader;
  web.WritableStreamDefaultWriter? _writer;
  final _received = StreamController<String>();
  bool _closing = false;

  @override
  String get description {
    final info = _port.getInfo();
    final vid = info.usbVendorId, pid = info.usbProductId;
    String hex(int v) => v.toRadixString(16).padLeft(4, '0');
    return vid == null ? tBoard.usbSerial : 'USB ${hex(vid)}:${hex(pid ?? 0)}';
  }

  @override
  int get window => 4;

  @override
  Future<void> open() async {
    try {
      await _port.open(_OpenOptions(baudRate: baud)).toDart;
    } catch (e) {
      throw StateError(tBoard.cannotOpenBrowserPort(e));
    }
    _writer = _port.writable!.getWriter();
    _reader = _port.readable!.getReader() as web.ReadableStreamDefaultReader;
    _readLoop();
  }

  Future<void> _readLoop() async {
    final reader = _reader!;
    try {
      while (true) {
        final result = await reader.read().toDart;
        if (result.done) break;
        final bytes = (result.value as JSUint8Array).toDart;
        _received.add(latin1.decode(bytes));
      }
      if (!_closing) _received.addError(StateError(tBoard.portClosed));
    } catch (e) {
      if (!_closing) _received.addError(e);
    } finally {
      await _received.close();
    }
  }

  @override
  Stream<String> get received => _received.stream;

  @override
  void send(String line) {
    final bytes = Uint8List.fromList(latin1.encode('$line\n'));
    _writer!.write(bytes.toJS).toDart.catchError((Object e) {
      if (!_closing) _received.addError(e);
      return null;
    });
  }

  @override
  Future<void> close() async {
    _closing = true;
    try {
      await _reader?.cancel().toDart;
      _reader?.releaseLock();
      _writer?.releaseLock();
      await _port.close().toDart;
    } catch (_) {}
  }
}
