import '../../core/assembler.dart';

/// The comment that explains [line] (0-based) of [source], or null.
///
/// That is the line's own comment, plus the comment-only lines directly
/// above it, which is how long explanations are written (the built-in
/// programs move a comment above its instruction when it would not fit on
/// the line). On a comment-only line, the whole run of comment lines it
/// belongs to is returned. Lines are joined with spaces, without the `;`.
String? commentForLine(String source, int line) {
  final lines = source.split('\n');
  if (line < 0 || line >= lines.length) return null;

  String? commentOf(String text) {
    final start = findCommentStart(text);
    if (start < 0) return null;
    final comment = text.substring(start + 1).trim();
    return comment.isEmpty ? null : comment;
  }

  bool isCommentOnly(String text) =>
      text.trim().startsWith(';') && commentOf(text) != null;

  final parts = <String>[];

  // The run of comment-only lines that ends just above [line], or that
  // [line] itself is part of.
  int top = line;
  while (top > 0 && isCommentOnly(lines[top - 1])) {
    top--;
  }
  int bottom = line;
  if (isCommentOnly(lines[line])) {
    while (bottom + 1 < lines.length && isCommentOnly(lines[bottom + 1])) {
      bottom++;
    }
  }
  for (int i = top; i <= bottom; i++) {
    if (i == line && !isCommentOnly(lines[i])) break;
    parts.add(commentOf(lines[i])!);
  }

  if (!isCommentOnly(lines[line])) {
    final own = commentOf(lines[line]);
    if (own != null) parts.add(own);
  }

  return parts.isEmpty ? null : parts.join(' ');
}
