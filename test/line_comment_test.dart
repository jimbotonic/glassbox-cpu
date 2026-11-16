import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_8_bit_cpu_simulator/ui/editor/line_comment.dart';

void main() {
  const source = '''; Text LCD: port 1 takes commands,
; port 2 characters
.equ LCD_CMD 1
        ; display on (starts off),
        ; no cursor
        LDI 0x0C
        OUT LCD_CMD
        CMP zero      ; end?
msg:    .db "a;b", 0

        HLT''';

  test('own comment', () {
    expect(commentForLine(source, 7), 'end?');
  });

  test('comment lines above an instruction are joined', () {
    expect(commentForLine(source, 5), 'display on (starts off), no cursor');
  });

  test('a comment-only line returns its whole run', () {
    expect(
      commentForLine(source, 0),
      'Text LCD: port 1 takes commands, port 2 characters',
    );
    expect(commentForLine(source, 4), 'display on (starts off), no cursor');
  });

  test('a run of comments only explains the line right below it', () {
    expect(commentForLine(source, 6), isNull);
    expect(
      commentForLine(source, 2),
      'Text LCD: port 1 takes commands, port 2 characters',
    );
  });

  test('a semicolon inside a string is not a comment', () {
    expect(commentForLine(source, 8), isNull);
  });

  test('blank lines, missing lines and no comment give null', () {
    expect(commentForLine(source, 9), isNull);
    expect(commentForLine(source, 10), isNull);
    expect(commentForLine(source, 99), isNull);
    expect(commentForLine(source, -1), isNull);
  });
}
