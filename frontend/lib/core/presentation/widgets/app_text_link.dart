import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';

/// A tappable piece of text without a box ("See all", "Cancel duel",
/// "Surrender", "Review"). The caller passes the exact Paper style.
final class AppTextLink extends StatelessWidget {
  const AppTextLink({
    required this.label,
    required this.style,
    required this.onPressed,
    this.textAlign,
    super.key,
  });

  final String label;
  final TextStyle style;
  final VoidCallback? onPressed;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AppTappable(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Text(label, style: style, textAlign: textAlign),
    );
  }
}
