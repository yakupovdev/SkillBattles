import 'package:material_ui/material_ui.dart';

/// The 16 x 9 notch on the top edge of a picker or bubble. Place it with
/// `Positioned(top: -8, ...)` inside a non-clipping `Stack`.
final class StickerCaret extends StatelessWidget {
  const StickerCaret({required this.fill, required this.stroke, super.key});

  final Color fill;
  final Color stroke;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 9),
      painter: _CaretPainter(fill: fill, stroke: stroke),
    );
  }
}

final class _CaretPainter extends CustomPainter {
  const _CaretPainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final Path triangle = Path()
      ..moveTo(0, 9)
      ..lineTo(8, 1)
      ..lineTo(16, 9)
      ..close();
    canvas.drawPath(triangle, Paint()..color = fill);
    final Path edges = Path()
      ..moveTo(0.5, 8.5)
      ..lineTo(8, 1)
      ..lineTo(15.5, 8.5);
    canvas.drawPath(
      edges,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = stroke,
    );
  }

  @override
  bool shouldRepaint(_CaretPainter oldDelegate) =>
      fill != oldDelegate.fill || stroke != oldDelegate.stroke;
}
