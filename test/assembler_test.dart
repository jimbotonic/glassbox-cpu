import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_8_bit_cpu_simulator/core/assembler.dart';

void main() {
  final assembler = Assembler();

  test('source map skips blank and comment-only lines', () {
    const source =
        '; multiply 7 x 3\n'
        'LDI #7\n'
        '\n'
        'STA 0xF   ; keep 7\n'
        '  ; comment only\n'
        'ADD 0xF\n'
        'HLT';

    final result = assembler.assembleWithSourceMap(source);

    expect(result.machineCode, [0x57, 0x4F, 0x2F, 0xF0]);
    expect(result.sourceLines, [1, 3, 5, 6]);
    expect(result.lineForAddress(0), 1);
    expect(result.lineForAddress(3), 6);
    expect(result.lineForAddress(4), isNull);
    expect(result.lineForAddress(-1), isNull);
  });

  test('assemble returns the same machine code as the source-map variant', () {
    const source = 'LDI #3\nOUT\nHLT';
    expect(
      assembler.assemble(source),
      assembler.assembleWithSourceMap(source).machineCode,
    );
  });
}
