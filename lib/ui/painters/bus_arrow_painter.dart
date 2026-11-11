import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/step_info.dart';

/// Draws an arrow from the module driving the bus to every module latching
/// it, over the whole board. Module positions come from [nodeKeys]; the
/// painter must fill the widget that owns [originKey].
class BusArrowPainter extends CustomPainter {
  final GlobalKey originKey;
  final Map<BusNode, GlobalKey> nodeKeys;
  final BusNode? source;
  final List<BusNode> destinations;
  final String label;

  BusArrowPainter({
    required this.originKey,
    required this.nodeKeys,
    required this.source,
    required this.destinations,
    required this.label,
  });

  static const Color _color = Colors.amber;

  Rect? _rectOf(BusNode node) {
    final origin = originKey.currentContext?.findRenderObject();
    final box = nodeKeys[node]?.currentContext?.findRenderObject();
    if (origin is! RenderBox || box is! RenderBox) return null;
    if (!box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero, ancestor: origin) & box.size;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final from = source == null ? null : _rectOf(source!);
    if (from == null) return;

    final glow = Paint()
      ..color = _color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = _color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final head = Paint()..color = _color;

    Offset? labelAt;
    for (final destination in destinations) {
      final to = _rectOf(destination);
      if (to == null || destination == source) continue;

      final (start, end, direction) = _anchors(from, to);
      final reach = (end - start).distance * 0.4;
      // Straight when the panels face each other, curved otherwise.
      final straight =
          (direction.dx != 0 && (start.dy - end.dy).abs() < 1) ||
          (direction.dy != 0 && (start.dx - end.dx).abs() < 1);
      final c1 = straight ? start : start + direction * reach;
      final c2 = straight ? start : end - direction * reach;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);

      canvas.drawPath(path, glow);
      canvas.drawPath(path, line);
      _drawHead(canvas, end, end - c2, head);
      // Label beside the arrow, not on it.
      labelAt ??=
          _bezier(start, c1, c2, end, 0.5) +
          (direction.dx != 0 ? const Offset(0, -14) : const Offset(26, 0));
    }

    if (labelAt != null) _drawLabel(canvas, labelAt);
  }

  /// How far the arrow starts inside the source panel, so that it stays
  /// visible when panels are only a narrow gap apart.
  static const double _inset = 28;

  /// Start and end points of the arrow from [a] to [b], and the direction
  /// it leaves [a]. When the panels overlap across the arrow's direction,
  /// the arrow runs straight through the middle of that overlap.
  (Offset, Offset, Offset) _anchors(Rect a, Rect b) {
    final overlapTop = math.max(a.top, b.top);
    final overlapBottom = math.min(a.bottom, b.bottom);
    final overlapLeft = math.max(a.left, b.left);
    final overlapRight = math.min(a.right, b.right);

    if (b.left >= a.right || b.right <= a.left) {
      final rightward = b.left >= a.right;
      final double sign = rightward ? 1 : -1;
      final startY = overlapBottom > overlapTop
          ? (overlapTop + overlapBottom) / 2
          : a.center.dy;
      final endY = overlapBottom > overlapTop ? startY : b.center.dy;
      final startX = rightward ? a.right - _inset : a.left + _inset;
      final endX = rightward ? b.left + 4 : b.right - 4;
      return (Offset(startX, startY), Offset(endX, endY), Offset(sign, 0));
    }

    final downward = b.top >= a.bottom;
    final double sign = downward ? 1 : -1;
    final startX = overlapRight > overlapLeft
        ? (overlapLeft + overlapRight) / 2
        : a.center.dx;
    final endX = overlapRight > overlapLeft ? startX : b.center.dx;
    final startY = downward ? a.bottom - _inset : a.top + _inset;
    final endY = downward ? b.top + 4 : b.bottom - 4;
    return (Offset(startX, startY), Offset(endX, endY), Offset(0, sign));
  }

  Offset _bezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    return p0 * (u * u * u) +
        p1 * (3 * u * u * t) +
        p2 * (3 * u * t * t) +
        p3 * (t * t * t);
  }

  void _drawHead(Canvas canvas, Offset tip, Offset direction, Paint paint) {
    if (direction.distance == 0) return;
    final angle = math.atan2(direction.dy, direction.dx);
    const length = 14.0;
    const spread = 0.45;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - length * math.cos(angle - spread),
        tip.dy - length * math.sin(angle - spread),
      )
      ..lineTo(
        tip.dx - length * math.cos(angle + spread),
        tip.dy - length * math.sin(angle + spread),
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawLabel(Canvas canvas, Offset center) {
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final box = Rect.fromCenter(
      center: center,
      width: text.width + 10,
      height: text.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(4)),
      Paint()..color = _color,
    );
    text.paint(canvas, box.topLeft + const Offset(5, 2));
  }

  @override
  bool shouldRepaint(BusArrowPainter old) => true;
}
