import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/question_option_entity.dart';
import 'package:skill_battles/core/presentation/markdown/markdown_spans.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_markdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';

/// Visual state of an answer option.
enum BattleOptionState { idle, selected, correct, wrong }

/// One answer option: letter badge, text and an optional trailing note.
final class BattleOptionCard extends StatelessWidget {
  const BattleOptionCard({
    required this.option,
    required this.letter,
    required this.state,
    required this.onPressed,
    this.trailingLabel,
    this.trailingAvatarNickname,
    super.key,
  });

  final QuestionOptionEntity option;

  /// Badge letter ("A".."D") by position.
  final String letter;
  final BattleOptionState state;

  /// Null when the option is not tappable.
  final VoidCallback? onPressed;

  /// Note at the end of the card ("Your answer", "You · +1,058").
  final String? trailingLabel;

  /// Shows an extra-small opponent avatar after the note.
  final String? trailingAvatarNickname;

  static String letterAt(int index) => String.fromCharCode(65 + index);

  @override
  Widget build(BuildContext context) {
    final (
      Color border,
      Color fill,
      Color letterBox,
      Color letterColor,
      Color note,
    ) = switch (state) {
      BattleOptionState.idle => (
        AppColors.border,
        AppColors.white,
        AppColors.surface,
        AppColors.ink,
        AppColors.muted,
      ),
      BattleOptionState.selected => (
        AppColors.primary,
        AppColors.primarySurface,
        AppColors.primary,
        AppColors.white,
        AppColors.primary,
      ),
      BattleOptionState.correct => (
        AppColors.success,
        AppColors.successSurface,
        AppColors.success,
        AppColors.white,
        AppColors.success,
      ),
      BattleOptionState.wrong => (
        AppColors.danger,
        AppColors.dangerSurface,
        AppColors.danger,
        AppColors.white,
        AppColors.dangerText,
      ),
    };
    final double borderWidth = state == BattleOptionState.idle ? 1.5 : 2;
    final String? label = trailingLabel;
    final String? avatar = trailingAvatarNickname;
    final String? stateWord = switch (state) {
      BattleOptionState.correct => 'Correct',
      BattleOptionState.wrong => 'Wrong',
      BattleOptionState.idle || BattleOptionState.selected => null,
    };
    final String semanticValue = <String>[?stateWord, ?label].join(', ');

    return AppTappable(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      isSelected: state == BattleOptionState.selected,
      semanticLabel: 'Answer $letter: ${MarkdownSpans.plainText(option.text)}',
      semanticValue: semanticValue.isEmpty ? null : semanticValue,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: borderWidth),
        ),
        child: Row(
          spacing: 16,
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: letterBox,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                letter,
                style: AppTextStyles.monoBodyLg.copyWith(color: letterColor),
              ),
            ),
            Expanded(
              child: AppMarkdownLine(
                option.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyAnswer,
              ),
            ),
            if (label != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.bodySm.copyWith(
                          color: note,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (avatar != null)
                      AppAvatar(
                        nickname: avatar,
                        size: AppAvatarSize.xs,
                        tone: AppAvatarTone.accent,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
