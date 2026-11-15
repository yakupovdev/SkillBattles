import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// Shows [child] at its natural size and scales it down, keeping the aspect
/// ratio, when it is wider than the incoming max width.
///
/// Unlike `FittedBox` and scroll views it reports the (scaled) baseline of
/// [child], so a formula inside a `WidgetSpan` stays on the text baseline.
final class MathFitWidth extends SingleChildRenderObjectWidget {
  const MathFitWidth({required Widget super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFitWidth();
}

final class _RenderFitWidth extends RenderProxyBox {
  double _scale = 1;

  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      BoxConstraints(maxHeight: constraints.maxHeight);

  double _scaleFor(Size natural, BoxConstraints constraints) =>
      natural.width > constraints.maxWidth && natural.width > 0
      ? constraints.maxWidth / natural.width
      : 1;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final RenderBox? child = this.child;
    if (child == null) return constraints.smallest;
    final Size natural = child.getDryLayout(_childConstraints(constraints));
    return constraints.constrain(natural * _scaleFor(natural, constraints));
  }

  @override
  void performLayout() {
    final RenderBox? child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    _scale = _scaleFor(child.size, constraints);
    size = constraints.constrain(child.size * _scale);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final double? childBaseline = child?.getDistanceToActualBaseline(baseline);
    return childBaseline == null ? null : childBaseline * _scale;
  }

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final RenderBox? child = this.child;
    if (child == null) return null;
    final BoxConstraints childConstraints = _childConstraints(constraints);
    final double? childBaseline = child.getDryBaseline(
      childConstraints,
      baseline,
    );
    if (childBaseline == null) return null;
    return childBaseline *
        _scaleFor(child.getDryLayout(childConstraints), constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? child = this.child;
    if (child == null) return;
    if (_scale == 1) {
      context.paintChild(child, offset);
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      Matrix4.diagonal3Values(_scale, _scale, 1),
      (PaintingContext context, Offset offset) =>
          context.paintChild(child, offset),
      oldLayer: layer is TransformLayer ? layer! as TransformLayer : null,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.scaleByDouble(_scale, _scale, 1, 1);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintTransform(
      transform: Matrix4.diagonal3Values(_scale, _scale, 1),
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) =>
          child?.hitTest(result, position: position) ?? false,
    );
  }
}
