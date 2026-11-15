import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';

/// 40 px icon button in the picker header that hides or shows the
/// opponent's stickers for this battle (Paper states H and I).
final class MuteOpponentToggle extends StatefulWidget {
  const MuteOpponentToggle({
    required this.isHidden,
    required this.opponentNickname,
    required this.onTap,
    super.key,
  });

  final bool isHidden;
  final String opponentNickname;
  final VoidCallback onTap;

  @override
  State<MuteOpponentToggle> createState() => _MuteOpponentToggleState();
}

final class _MuteOpponentToggleState extends State<MuteOpponentToggle> {
  late bool _isHovered;

  @override
  void initState() {
    super.initState();
    _isHovered = false;
  }

  void _setHovered(bool value) {
    if (value == _isHovered) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool isHidden = widget.isHidden;
    final String message = isHidden
        ? "Show ${widget.opponentNickname}'s stickers"
        : "Hide ${widget.opponentNickname}'s stickers";
    final Color fill = isHidden
        ? AppColors.accentTint
        : _isHovered
        ? AppColors.surface
        : const Color(0x00000000);
    return Tooltip(
      message: message,
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: AppTappable(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          semanticLabel: message,
          isSelected: isHidden,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox.square(
              dimension: 40,
              child: Center(
                child: AppSvgIcon(
                  isHidden ? AppIcons.eyeOff : AppIcons.eye,
                  width: 18,
                  height: 18,
                  color: isHidden ? AppColors.accentText : AppColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
