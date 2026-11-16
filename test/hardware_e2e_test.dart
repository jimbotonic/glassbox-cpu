// End to end: GlassBox's WebSocket link and bridge against the Raspberry
// Pi bridge script in --simulate mode. Skipped without python3.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_8_bit_cpu_simulator/core/assembler.dart';
import 'package:flutter_8_bit_cpu_simulator/core/builtin_program_list.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu.dart';
import 'package:flutter_8_bit_cpu_simulator/core/cpu_mode.dart';
import 'package:flutter_8_bit_cpu_simulator/core/io/bridge/hardware_bridge.dart';
import 'package:flutter_8_bit_cpu_simulator/hardware/websocket_link.dart';
import 'package:flutter_test/flutter_test.dart';

const script = 'firmware/raspberry-pi/glassbox_bridge.py';

Future<int> freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

void main() {
  final python = Process.runSync('which', ['python3']).exitCode == 0;

  test('mirrors a program to the Raspberry Pi bridge', () async {
    final port = await freePort();
    final process = await Process.start('python3', [
      '-I',
      script,
      '--ws',
      '127.0.0.1:$port',
      '--simulate',
    ]);
    addTearDown(process.kill);
    final stdout = StringBuffer();
    process.stdout.transform(utf8.decoder).listen(stdout.write);
    final ready = Completer<void>();
    process.stderr.transform(utf8.decoder).listen((s) {
      if (s.contains('WebSocket server') && !ready.isCompleted) {
        ready.complete();
      }
    });
    await ready.future.timeout(const Duration(seconds: 10));

    const extended = CpuMode.extended;
    final cpu = Cpu(mode: extended);
    final bridge = HardwareBridge(cpu);
    await bridge.connect(WebSocketLink.parse('127.0.0.1:$port'));
    expect(bridge.board!.board, 'simulator');

    Future<void> run(String name) async {
      cpu.load(
        Assembler(
          mode: extended,
        ).assemble(BuiltinProgramList.getByName(name)!.code),
      );
      while (!cpu.halted) {
        cpu.stepInstruction();
      }
      // Wait until every line is answered and the terminal redrawn.
      for (int i = 0; i < 100 && bridge.queued + bridge.inFlight > 0; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
      expect(bridge.queued + bridge.inFlight, 0);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    await run('LCD: Hello, world');
    var screen = stdout.toString().split('\x1b[H\x1b[2J').last;
    expect(screen, contains('|Hello, world!   |'));
    expect(screen, contains('|GlassBox CPU    |'));

    // load() resets the devices: the bridge replays, the LCD goes blank.
    await run('LED matrix: smiley');
    screen = stdout.toString().split('\x1b[H\x1b[2J').last;
    expect(screen, contains('display off'));
    expect(screen, contains('· · ● ● ● ● · ·   0x3C'));
    expect(screen, contains('● · ● · · ● · ●   0xA5'));

    await bridge.disconnect();
  }, skip: python ? false : 'python3 not found');
}
