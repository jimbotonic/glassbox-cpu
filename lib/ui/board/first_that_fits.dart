import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Shows the first child whose natural (max intrinsic) width fits the
/// width available, or the last child when none does.
///
/// Lets a bar pick its layout from what its text needs, whatever the
/// language, rather than from a fixed breakpoint. Children must support
/// intrinsic sizing (no LayoutBuilder inside).
class FirstThatFits extends MultiChildRenderObjectWidget {
  const FirstThatFits({super.key, required super.children});

  @override
  RenderFirstThatFits createRenderObject(BuildContext context) =>
      RenderFirstThatFits();
}

class _FitParentData extends ContainerBoxParentData<RenderBox> {}

class RenderFirstThatFits extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FitParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FitParentData> {
  RenderBox? _shown;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FitParentData) {
      child.parentData = _FitParentData();
    }
  }

  RenderBox? _pick(double maxWidth) {
    var child = firstChild;
    while (child != null) {
      if (child == lastChild ||
          child.getMaxIntrinsicWidth(double.infinity) <= maxWidth) {
        return child;
      }
      child = childAfter(child);
    }
    return null;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      lastChild?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      firstChild?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _pick(width)?.getMinIntrinsicHeight(width) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _pick(width)?.getMaxIntrinsicHeight(width) ?? 0;

  @override
  void performLayout() {
    _shown = _pick(constraints.maxWidth);
    final shown = _shown;
    if (shown == null) {
      size = constraints.smallest;
      return;
    }
    shown.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(
      Size(math.max(shown.size.width, 0), shown.size.height),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final shown = _shown;
    if (shown != null) context.paintChild(shown, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final shown = _shown;
    if (shown == null) return false;
    return result.addWithPaintOffset(
      offset: Offset.zero,
      position: position,
      hitTest: (result, transformed) =>
          shown.hitTest(result, position: transformed),
    );
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    final shown = _shown;
    if (shown != null) visitor(shown);
  }
}
