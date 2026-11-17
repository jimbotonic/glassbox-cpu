import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A column that, given more height than its children need, makes each
/// child taller by an equal share, up to [maxGrow]; whatever is left after
/// that widens the gaps, so the last child always ends at the bottom.
///
/// Children are laid out with a tight height, so they should fill it (a
/// panel that centres its content, say). With unbounded height it is a
/// plain column with [gap] between children.
class GrowColumn extends MultiChildRenderObjectWidget {
  final double gap;
  final double maxGrow;

  const GrowColumn({
    super.key,
    required this.gap,
    required this.maxGrow,
    required super.children,
  });

  @override
  RenderGrowColumn createRenderObject(BuildContext context) =>
      RenderGrowColumn(gap: gap, maxGrow: maxGrow);

  @override
  void updateRenderObject(BuildContext context, RenderGrowColumn render) {
    render
      ..gap = gap
      ..maxGrow = maxGrow;
  }
}

class _GrowParentData extends ContainerBoxParentData<RenderBox> {}

class RenderGrowColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GrowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GrowParentData> {
  RenderGrowColumn({required double gap, required double maxGrow})
    : _gap = gap,
      _maxGrow = maxGrow;

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  double _maxGrow;
  set maxGrow(double value) {
    if (value == _maxGrow) return;
    _maxGrow = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GrowParentData) {
      child.parentData = _GrowParentData();
    }
  }

  List<RenderBox> get _children {
    final list = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      list.add(child);
      child = childAfter(child);
    }
    return list;
  }

  double _gaps() => childCount > 1 ? _gap * (childCount - 1) : 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _children.fold(0.0, (s, c) => s + c.getMinIntrinsicHeight(width)) +
      _gaps();

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _children.fold(0.0, (s, c) => s + c.getMaxIntrinsicHeight(width)) +
      _gaps();

  @override
  double computeMinIntrinsicWidth(double height) => _children.fold(
    0.0,
    (m, c) => math.max(m, c.getMinIntrinsicWidth(double.infinity)),
  );

  @override
  double computeMaxIntrinsicWidth(double height) => _children.fold(
    0.0,
    (m, c) => math.max(m, c.getMaxIntrinsicWidth(double.infinity)),
  );

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final children = _children;
    final natural = [for (final c in children) c.getMaxIntrinsicHeight(width)];
    final needed = natural.fold(0.0, (s, h) => s + h) + _gaps();
    final spare = constraints.hasBoundedHeight
        ? math.max(0.0, constraints.maxHeight - needed)
        : 0.0;
    final grow = children.isEmpty
        ? 0.0
        : math.min(_maxGrow, spare / children.length);
    final left = spare - grow * children.length;
    final gap = _gap + (children.length > 1 ? left / (children.length - 1) : 0);

    var y = 0.0;
    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      child.layout(
        BoxConstraints.tightFor(width: width, height: natural[i] + grow),
        parentUsesSize: true,
      );
      (child.parentData! as _GrowParentData).offset = Offset(0, y);
      y += child.size.height + (i < children.length - 1 ? gap : 0);
    }
    size = constraints.constrain(
      Size(width, children.length == 1 ? y + left : y),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
