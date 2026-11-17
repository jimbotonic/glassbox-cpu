import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/io/bridge/hardware_bridge.dart';
import '../l10n/board_strings.dart';

/// A board on Wi-Fi: the ESP32 sketch or the Raspberry Pi bridge runs a
/// WebSocket server, e.g. `ws://192.168.1.50:81`.
class WebSocketLink implements HardwareLink {
  WebSocketLink(this.uri);

  /// Accepts `192.168.1.50`, `192.168.1.50:81` or a full `ws://` URL; the
  /// port defaults to 81, the firmware's.
  factory WebSocketLink.parse(String address) =>
      WebSocketLink(parseAddress(address));

  static Uri parseAddress(String address) {
    address = address.trim();
    if (address.isEmpty) throw FormatException(tBoard.enterAddress);
    if (!address.contains('://')) address = 'ws://$address';
    final uri = Uri.parse(address);
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      throw FormatException(tBoard.useWs(uri.scheme));
    }
    if (uri.host.isEmpty) throw FormatException(tBoard.noHost);
    return uri.hasPort ? uri : uri.replace(port: 81);
  }

  final Uri uri;
  WebSocketChannel? _channel;

  @override
  String get description => uri.toString();

  /// Wi-Fi boards read whole frames into a large buffer.
  @override
  int get window => 32;

  @override
  Future<void> open() async {
    final channel = WebSocketChannel.connect(uri);
    await channel.ready.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException(tBoard.noWebSocket('$uri')),
    );
    _channel = channel;
  }

  @override
  Stream<String> get received => _channel!.stream.map(
    (m) => m is String ? m : latin1.decode(m as List<int>),
  );

  @override
  void send(String line) => _channel!.sink.add('$line\n');

  @override
  Future<void> close() async => _channel?.sink.close();
}
