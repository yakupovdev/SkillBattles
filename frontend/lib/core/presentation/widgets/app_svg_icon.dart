import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A decorative SVG icon from `AppIcons`.
///
/// The size is always explicit, so the layout does not move while the file
/// loads. [color], when given, replaces every color of the icon (the file
/// becomes a CSS mask filled with the color); without it the file keeps its
/// own colors.
final class AppSvgIcon extends StatelessComponent {
  const AppSvgIcon(
    this.asset, {
    required this.width,
    required this.height,
    this.color,
    super.key,
  });

  final String asset;
  final double width;
  final double height;
  final Color? color;

  @override
  Component build(BuildContext context) {
    final Color? tint = color;
    if (tint == null) {
      return img(
        src: asset,
        alt: '',
        width: width.round(),
        height: height.round(),
        classes: 'app-svg-icon',
        styles: Styles(
          width: Unit.pixels(width),
          height: Unit.pixels(height),
        ),
        attributes: const <String, String>{'aria-hidden': 'true'},
      );
    }
    return span(
      classes: 'app-svg-icon',
      styles: Styles(
        display: Display.inlineBlock,
        width: Unit.pixels(width),
        height: Unit.pixels(height),
        backgroundColor: tint,
        raw: <String, String>{
          'mask': 'url("$asset") center / contain no-repeat',
          '-webkit-mask': 'url("$asset") center / contain no-repeat',
        },
      ),
      attributes: const <String, String>{'aria-hidden': 'true'},
      const <Component>[],
    );
  }
}

@css
List<StyleRule> get appSvgIconStyles => <StyleRule>[
  css('.app-svg-icon').styles(
    flex: const Flex(shrink: 0),
  ),
];
