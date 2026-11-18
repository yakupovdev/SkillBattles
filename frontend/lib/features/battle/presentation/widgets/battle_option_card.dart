import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

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
final class BattleOptionCard extends StatelessComponent {
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
  Component build(BuildContext context) {
    final (Color border, Color fill, Color letterBox, Color letterColor, Color note) = switch (state) {
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
      radius: 14,
      isSelected: state == BattleOptionState.selected,
      semanticLabel: 'Answer $letter: ${MarkdownSpans.plainText(option.text)}',
      semanticValue: semanticValue.isEmpty ? null : semanticValue,
      classes: 'battle-option-card',
      styles: Styles(
        border: Border.all(color: border, width: Unit.pixels(borderWidth)),
        backgroundColor: fill,
      ),
      child: Component.fragment(<Component>[
        span(
          classes: 'battle-option-card__letter',
          styles: Styles(color: letterColor, backgroundColor: letterBox),
          attributes: const <String, String>{'aria-hidden': 'true'},
          <Component>[Component.text(letter)],
        ),
        div(classes: 'battle-option-card__text', <Component>[
          AppMarkdownLine(option.text, maxLines: 3, style: AppTextStyles.bodyAnswer),
        ]),
        if (label != null)
          div(classes: 'battle-option-card__note', <Component>[
            span(
              classes: 'battle-option-card__note-text',
              styles: Styles(color: note),
              <Component>[Component.text(label)],
            ),
            if (avatar != null) AppAvatar(nickname: avatar, size: AppAvatarSize.xs, tone: AppAvatarTone.accent),
          ]),
      ]),
    );
  }
}

@css
List<StyleRule> get battleOptionCardStyles => <StyleRule>[
  css('.battle-option-card').styles(
    display: Display.flex,
    minHeight: const Unit.pixels(76),
    padding: const Padding.symmetric(horizontal: Unit.pixels(20), vertical: Unit.pixels(12)),
    boxSizing: BoxSizing.borderBox,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
    raw: const <String, String>{
      'transition': 'background-color 120ms, border-color 120ms',
    },
  ),
  css('.battle-option-card__letter')
      .styles(
        display: Display.flex,
        width: const Unit.pixels(36),
        height: const Unit.pixels(36),
        radius: const BorderRadius.circular(Unit.pixels(9)),
        justifyContent: JustifyContent.center,
        alignItems: AlignItems.center,
        flex: const Flex(shrink: 0),
      )
      .combine(AppTextStyles.monoBodyLg),
  css('.battle-option-card__text').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.battle-option-card__note').styles(
    display: Display.flex,
    maxWidth: const Unit.pixels(240),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
    flex: const Flex(shrink: 0),
  ),
  css('.battle-option-card__note-text')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        textAlign: TextAlign.right,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(fontWeight: FontWeight.w600)),
];
