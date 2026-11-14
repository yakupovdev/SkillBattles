import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// A decorative SVG icon from `AppIcons`.
///
/// The size is always explicit, so the layout does not move while the file
/// loads. [color], when given, replaces every color of the icon.
final class AppSvgIcon extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final Color? tint = color;
    return SvgPicture.asset(
      asset,
      width: width,
      height: height,
      excludeFromSemantics: true,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
