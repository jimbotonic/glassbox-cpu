import 'dart:async';
import 'dart:collection';

import '../../cpu.dart';
import '../keypad.dart';
import 'protocol.dart';

/// A byte pipe to a board: a USB serial port or a WebSocket.
abstract class HardwareLink {
  /// Shown in the UI, e.g. `USB /dev/ttyUSB0` or `ws://192.168.1.50:81`.
  String get description;

  /// How many lines may wait for an answer at once. A serial board reads
  /// into a small buffer (64 bytes on an Uno), so keep it low there.
  int get window;

  /// Connects; throws if the port or host cannot be opened.
  Future<void> open();

  /// Text from the board, in chunks of any size.
  Stream<String> get received;

  /// Sends [line] followed by `\n`.
  void send(String line);

  Future<void> close();
}

enum BridgeStatus { disconnected, connecting, connected }

/// Mirrors the CPU's I/O ports onto a real board and feeds its keypad back.
///
/// Every port write goes out as a `W` line. When the devices jump to
/// another state instead (reset, step-back), the board is reset and the
/// whole state is replayed, so it always shows what the screen shows.
class HardwareBridge {
  HardwareBridge(
    this.cpu, {
    this.onChange,
    this.helloTimeout = const Duration(seconds: 6),
    this.helloRetry = const Duration(milliseconds: 800),
    this.ackTimeout = const Duration(seconds: 3),
  });

  final Cpu cpu;

  /// Called whenever [status], [board], [log] or the keypad changed.
  final void Function()? onChange;

  /// How long a board may take to answer `HELLO`. Opening the serial port
  /// of an Uno or Nano reboots it, which takes about two seconds.
  final Duration helloTimeout;
  final Duration helloRetry;

  /// Lines unanswered for this long are given up and the state resent.
  final Duration ackTimeout;

  /// Writes waiting to be sent beyond this many are dropped for a resync.
  static const int maxQueue = 4096;
  static const int maxLog = 100;

  BridgeStatus get status => _status;
  BridgeStatus _status = BridgeStatus.disconnected;

  HardwareLink? get link => _link;
  HardwareLink? _link;

  /// What the board said in its `GLASSBOX` line, once connected.
  BoardHello? get board => _board;
  BoardHello? _board;

  /// The reason the last connection failed or ended, if it was not asked.
  String? get error => _error;
  String? _error;

  /// Board log lines, errors and connection events, oldest first.
  List<String> get log => List.unmodifiable(_log);
  final ListQueue<String> _log = ListQueue();

  /// Lines not yet sent, and lines sent but not yet answered.
  int get queued => _queue.length;
  int get inFlight => _inFlight;

  final ListQueue<String> _queue = ListQueue();
  int _inFlight = 0;
  bool _resyncScheduled = false;
  StreamSubscription<String>? _subscription;
  final LineSplitter _lines = LineSplitter();
  Completer<BoardHello>? _hello;
  Timer? _ackTimer;

  /// Opens [link], shakes hands, then mirrors the ports. Throws (after
  /// closing the link) if it cannot open or the board never answers.
  Future<void> connect(HardwareLink link) async {
    await disconnect();
    _link = link;
    _error = null;
    _board = null;
    _setStatus(BridgeStatus.connecting);
    _note('Connecting to ${link.description}');
    try {
      await link.open();
      final hello = _hello = Completer<BoardHello>();
      _subscription = link.received.listen(
        _receive,
        onError: (Object e) => _lost('Link error: $e'),
        onDone: () => _lost('${link.description} closed'),
      );
      final retry = Timer.periodic(helloRetry, (_) => _sendRaw(helloLine()));
      _sendRaw(helloLine());
      final BoardHello board;
      try {
        board = await hello.future.timeout(
          helloTimeout,
          onTimeout: () => throw TimeoutException(
            'No answer from the board. Is the GlassBox firmware on it, '
            'at the right speed?',
          ),
        );
      } finally {
        retry.cancel();
        _hello = null;
      }
      if (board.version != protocolVersion) {
        throw StateError(
          'The board speaks protocol ${board.version}; this GlassBox '
          'speaks $protocolVersion. Update the firmware.',
        );
      }
      if (_link != link) return; // disconnected meanwhile
      _board = board;
      _queue.clear();
      _inFlight = 0;
      cpu.io.addListener(_onWrite);
      cpu.io.addStateListener(_scheduleResync);
      _setStatus(BridgeStatus.connected);
      _note(
        'Connected: ${board.board} with '
        '${board.parts.isEmpty ? 'no parts' : board.parts.map((p) => p.name).join(', ')}',
      );
      _scheduleResync();
    } catch (e) {
      final message = e is TimeoutException ? e.message ?? '$e' : '$e';
      await _teardown();
      _error = message;
      _note('Failed: $message');
      _setStatus(BridgeStatus.disconnected);
      rethrow;
    }
  }

  /// Closes the link. The simulated devices keep their state.
  Future<void> disconnect() async {
    if (_link == null) return;
    final description = _link!.description;
    await _teardown();
    _note('Disconnected from $description');
    _setStatus(BridgeStatus.disconnected);
  }

  /// Sends the whole device state again, e.g. after unplugging the LCD.
  void resync() => _scheduleResync();

  Future<void> _teardown() async {
    cpu.io.removeListener(_onWrite);
    cpu.io.removeStateListener(_scheduleResync);
    _ackTimer?.cancel();
    _ackTimer = null;
    final link = _link, subscription = _subscription;
    _link = null;
    _subscription = null;
    _board = null;
    _queue.clear();
    _inFlight = 0;
    await subscription?.cancel();
    try {
      await link?.close();
    } catch (_) {}
  }

  void _lost(String reason) {
    if (_link == null) return;
    final hello = _hello;
    if (hello != null && !hello.isCompleted) {
      hello.completeError(StateError(reason));
      return; // connect() reports it
    }
    _teardown();
    _error = reason;
    _note(reason);
    _setStatus(BridgeStatus.disconnected);
  }

  void _onWrite(int port, int value) => _enqueue([writeLine(port, value)]);

  void _scheduleResync() {
    if (_resyncScheduled || _status != BridgeStatus.connected) return;
    _resyncScheduled = true;
    // After the current step or restore, so the replay sees its result.
    scheduleMicrotask(() {
      _resyncScheduled = false;
      if (_status != BridgeStatus.connected) return;
      _queue.clear(); // superseded by the replay
      _enqueue([
        resetLine,
        writeLine(0, cpu.outputRegister),
        for (final (port, value) in cpu.io.replay()) writeLine(port, value),
      ]);
    });
  }

  void _enqueue(List<String> lines) {
    if (_status != BridgeStatus.connected) return;
    _queue.addAll(lines);
    if (_queue.length > maxQueue) {
      _note('The board cannot keep up; resending the state instead');
      _queue.clear();
      _scheduleResync();
      return;
    }
    _pump();
  }

  void _pump() {
    final link = _link;
    if (link == null) return;
    while (_inFlight < link.window && _queue.isNotEmpty) {
      _inFlight++;
      _sendRaw(_queue.removeFirst());
    }
    _armAckTimer();
  }

  void _armAckTimer() {
    _ackTimer?.cancel();
    _ackTimer = _inFlight == 0
        ? null
        : Timer(ackTimeout, () {
            _note('No answer for $_inFlight line(s); resending the state');
            _inFlight = 0;
            _scheduleResync();
          });
  }

  void _sendRaw(String line) {
    try {
      _link?.send(line);
    } catch (e) {
      _lost('Send failed: $e');
    }
  }

  void _receive(String chunk) {
    for (final line in _lines.add(chunk)) {
      final message = BoardMessage.parse(line);
      switch (message) {
        case BoardHello():
          final hello = _hello;
          if (hello != null && !hello.isCompleted) hello.complete(message);
        case Ack():
          _answered();
        case BoardError(:final message):
          _note('Board refused a line: $message');
          _answered();
        case KeyPress(:final code):
          _keyPressed(code);
        case BoardLog(:final message):
          _note('board: $message');
        case null:
          break;
      }
    }
  }

  void _answered() {
    if (_status != BridgeStatus.connected || _inFlight == 0) return;
    _inFlight--;
    _pump();
  }

  void _keyPressed(int code) {
    final key = String.fromCharCode(code);
    final keypad = cpu.io.device<Keypad>();
    if (keypad == null || !Keypad.layout.contains(key)) {
      _note("Key '$key' from the board is not on the keypad");
      return;
    }
    keypad.press(key);
    onChange?.call();
  }

  void _note(String line) {
    _log.addLast(line);
    while (_log.length > maxLog) {
      _log.removeFirst();
    }
    onChange?.call();
  }

  void _setStatus(BridgeStatus status) {
    _status = status;
    onChange?.call();
  }
}
