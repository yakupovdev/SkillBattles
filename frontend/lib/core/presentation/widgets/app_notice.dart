import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';

/// Color of an [AppNotice].
enum AppNoticeTone {
  info(AppColors.primaryTint, AppColors.primary, AppColors.inkSoft),
  warning(AppColors.accentSurface, AppColors.accent, AppColors.accentInk),
  danger(AppColors.dangerSurface, AppColors.danger, AppColors.inkSoft),
  success(AppColors.successSurface, AppColors.success, AppColors.inkSoft);

  const AppNoticeTone(this.background, this.dot, this.text);

  final Color background;
  final Color dot;
  final Color text;
}

/// A tinted one-line note with a dot and an optional action link.
final class AppNotice extends StatelessWidget {
  const AppNotice({
    required this.message,
    this.tone = AppNoticeTone.info,
    this.actionLabel,
    this.onAction,
    this.hug = false,
    super.key,
  });

  final String message;
  final AppNoticeTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Whether the note hugs its text (left aligned, 14 px vertical padding)
  /// instead of taking the full width ("Private duels never change your
  /// rating.").
  final bool hug;

  @override
  Widget build(BuildContext context) {
    final String? label = actionLabel;
    final Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: hug ? 14 : 12),
        child: Row(
          mainAxisSize: hug ? MainAxisSize.min : MainAxisSize.max,
          spacing: 10,
          children: <Widget>[
            AppDot(color: tone.dot),
            Flexible(
              fit: hug ? FlexFit.loose : FlexFit.tight,
              child: Text(
                message,
                style: AppTextStyles.bodyMd.copyWith(color: tone.text),
              ),
            ),
            if (label != null)
              AppTextLink(
                label: label,
                style: AppTextStyles.buttonMd.copyWith(color: AppColors.ink),
                onPressed: onAction,
              ),
          ],
        ),
      ),
    );
    return Semantics(
      liveRegion: true,
      child: hug ? Align(alignment: Alignment.centerLeft, child: box) : box,
    );
  }
}
