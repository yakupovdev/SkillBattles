import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Hosts a page laid out for the 1440 × 900 desktop artboards.
///
/// - The content is centered and capped at [maxWidth] (the artboard width),
///   unless [fullBleed] is set: then the child spans the whole window and
///   caps its own content columns (used where a background or a rule runs
///   edge to edge on the artboard, e.g. auth halves, battle header line).
/// - Below [minWidth] the page scrolls horizontally instead of squeezing the
///   artboard columns.
/// - The page scrolls vertically. The child gets the window height as its
///   minimum height and no maximum, so it grows with its content.
///
/// Layout contract for the child: place content vertically with a `Column`'s
/// `mainAxisAlignment` (`center`, `spaceBetween`, ...) — it fills the
/// minimum height. Do not use vertical `Expanded` / `Spacer` / stretch, which
/// need a bounded height and fail immediately (at every window size).
final class AppDesktopViewport extends StatelessWidget {
  const AppDesktopViewport({
    required this.child,
    // The artboards' fixed columns stop fitting well below ~1280 and there
    // is no narrower design, so narrower windows scroll horizontally.
    this.minWidth = 1280,
    this.maxWidth = 1440,
    this.fullBleed = false,
    super.key,
  });

  final Widget child;
  final double minWidth;
  final double maxWidth;
  final bool fullBleed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = math.max(constraints.maxWidth, minWidth);
        final double sideInset = fullBleed
            ? 0
            : math.max(0, (width - maxWidth) / 2);
        final Widget page = SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sideInset),
              child: child,
            ),
          ),
        );
        if (constraints.maxWidth >= minWidth) return page;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: minWidth,
            height: constraints.maxHeight,
            child: page,
          ),
        );
      },
    );
  }
}
