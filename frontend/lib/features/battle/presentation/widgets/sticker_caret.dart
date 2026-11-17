import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The 16 x 9 notch on the top edge of a picker or bubble. Its root is
/// absolutely positioned 8 px above the top edge of its positioned parent;
/// pass the horizontal place with [left] or [right].
final class StickerCaret extends StatelessComponent {
  const StickerCaret({required this.fill, required this.stroke, this.left, this.right, super.key});

  final Color fill;
  final Color stroke;

  /// Distance of the caret's left edge from the parent's left edge, px.
  final double? left;

  /// Distance of the caret's right edge from the parent's right edge, px.
  final double? right;

  @override
  Component build(BuildContext context) {
    final double? left = this.left;
    final double? right = this.right;
    return svg(
      classes: 'sticker-caret',
      width: const Unit.pixels(16),
      height: const Unit.pixels(9),
      viewBox: '0 0 16 9',
      styles: Styles(
        position: Position.absolute(
          top: const Unit.pixels(-8),
          left: left == null ? null : Unit.pixels(left),
          right: right == null ? null : Unit.pixels(right),
        ),
      ),
      attributes: const <String, String>{'aria-hidden': 'true'},
      <Component>[
        path(d: 'M0 9 L8 1 L16 9 Z', fill: fill, const <Component>[]),
        path(
          d: 'M0.5 8.5 L8 1 L15.5 8.5',
          fill: Colors.transparent,
          stroke: stroke,
          strokeWidth: '1',
          const <Component>[],
        ),
      ],
    );
  }
}

@css
List<StyleRule> get stickerCaretStyles => <StyleRule>[
  css('.sticker-caret').styles(pointerEvents: PointerEvents.none, raw: const <String, String>{'overflow': 'visible'}),
];
