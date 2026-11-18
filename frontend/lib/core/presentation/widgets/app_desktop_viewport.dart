import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Hosts a page laid out for the 1440 × 900 desktop artboards.
///
/// - It fills its nearest positioned ancestor (the page area of `AppShell`,
///   or the browser window for full-screen pages) and is the page's scroll
///   container.
/// - The content is centered and capped at [maxWidth] (the artboard width),
///   unless [fullBleed] is set: then the child spans the whole window and
///   caps its own content columns (used where a background or a rule runs
///   edge to edge on the artboard, e.g. auth halves, battle header line).
/// - Below [minWidth] the page scrolls horizontally instead of squeezing the
///   artboard columns.
/// - The page scrolls vertically. The child's root element is a flex item
///   of a column that is at least as high as the viewport, so it grows to
///   the window height and further with its content.
///
/// Layout contract for the child: its root element fills the minimum
/// height; place content vertically with flex (`justify-content: center`,
/// `space-between`, ...) inside it.
final class AppDesktopViewport extends StatelessComponent {
  const AppDesktopViewport({
    required this.child,
    // The artboards' fixed columns stop fitting well below ~1280 and there
    // is no narrower design, so narrower windows scroll horizontally.
    this.minWidth = 1280,
    this.maxWidth = 1440,
    this.fullBleed = false,
    super.key,
  });

  final Component child;
  final double minWidth;
  final double maxWidth;
  final bool fullBleed;

  @override
  Component build(BuildContext context) {
    final String inset = 'max(0px, calc((100% - ${maxWidth}px) / 2))';
    return div(classes: 'app-viewport', <Component>[
      div(
        classes: 'app-viewport__page',
        styles: Styles(
          minWidth: Unit.pixels(minWidth),
          padding: fullBleed ? null : Padding.symmetric(horizontal: Unit.expression(inset)),
        ),
        <Component>[child],
      ),
    ]);
  }
}

@css
List<StyleRule> get appDesktopViewportStyles => <StyleRule>[
  css('.app-viewport').styles(
    position: const Position.absolute(top: Unit.zero, left: Unit.zero, right: Unit.zero, bottom: Unit.zero),
    overflow: Overflow.auto,
  ),
  css('.app-viewport__page').styles(
    display: Display.flex,
    minHeight: const Unit.percent(100),
    flexDirection: FlexDirection.column,
  ),
  css('.app-viewport__page > *').styles(flex: const Flex(grow: 1, shrink: 0, basis: Unit.auto)),
];
