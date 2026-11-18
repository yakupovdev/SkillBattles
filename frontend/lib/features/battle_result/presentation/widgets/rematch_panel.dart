import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/extensions/play_failure_message.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_status.dart';
import 'package:skill_battles/features/battle_result/presentation/bloc/battle_result_bloc/battle_result_bloc.dart';

/// Rematch after a private duel (Paper: "18 Result — Private, Overtime,
/// Rematch"): one click only asks; the new duel starts when both agreed
/// within 60 s, and both pass Ready again. Also holds the way home, so the
/// private result has no separate action row.
final class RematchPanel extends StatelessComponent {
  const RematchPanel({
    required this.myUserId,
    required this.opponentNickname,
    required this.disciplineCode,
    super.key,
  });

  final String myUserId;
  final String opponentNickname;
  final String disciplineCode;

  static String _failureText(Failure failure) {
    if (failure.hasCode(ApiErrorCodes.rematchExpired)) {
      return 'The rematch window has closed.';
    }
    if (failure.hasCode(ApiErrorCodes.rematchNotAllowed)) {
      return 'A rematch is no longer possible for this match.';
    }
    return failure.playMessage(DateTime.now());
  }

  @override
  Component build(BuildContext context) {
    return BlocSignalBuilder<BattleResultBloc, BattleResultState>(
      buildWhen: (BattleResultState previous, BattleResultState current) =>
          previous.rematch != current.rematch ||
          previous.rematchActionStatus != current.rematchActionStatus ||
          previous.rematchFailure != current.rematchFailure,
      builder: (BuildContext context, BattleResultState state) {
        final RematchEntity? rematch = state.rematch;
        final bool busy = state.rematchActionStatus.isLoading;
        final Failure? failure = state.rematchFailure;
        final BattleResultBloc bloc = context.read<BattleResultBloc>();
        void ask() => bloc.add(const BattleResultRematchRequested());
        void cancel() => bloc.add(const BattleResultRematchCancelled());
        void newDuel() => context.goPrivateDuel(disciplineCode: disciplineCode);

        final _PanelContent content = switch (rematch) {
          null => _PanelContent(
            title: 'Play $opponentNickname again?',
            message:
                "Ask for a rematch — it starts once you both agree. You'll "
                'both press Ready again.',
            action: AppButton(
              label: busy ? 'Asking…' : 'Ask for a rematch',
              size: AppButtonSize.small,
              onPressed: busy ? null : ask,
            ),
          ),
          RematchEntity(status: RematchStatus.waiting) when rematch.hasConsentOf(myUserId) => _PanelContent(
            title: 'Rematch requested',
            message:
                "Waiting for $opponentNickname to accept. You'll both "
                'press Ready again.',
            expiresAt: rematch.expiresAt,
            action: AppButton(
              label: 'Cancel request',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.small,
              onPressed: busy ? null : cancel,
            ),
          ),
          RematchEntity(status: RematchStatus.waiting) => _PanelContent(
            title: '$opponentNickname wants a rematch',
            message:
                "Accept before the timer runs out. You'll both press "
                'Ready again.',
            expiresAt: rematch.expiresAt,
            action: AppButton(
              label: busy ? 'Joining…' : 'Accept rematch',
              size: AppButtonSize.small,
              onPressed: busy ? null : ask,
            ),
          ),
          RematchEntity(status: RematchStatus.matched) => const _PanelContent(
            title: 'Rematch on',
            message: 'Opening the ready check…',
          ),
          RematchEntity(status: RematchStatus.expired) => _PanelContent(
            title: 'The rematch request expired',
            message: 'You can still start a new private duel.',
            isActive: false,
            action: AppButton(
              label: 'New private duel',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.small,
              onPressed: newDuel,
            ),
          ),
          RematchEntity(status: RematchStatus.cancelled) => _PanelContent(
            title: 'The rematch was cancelled',
            message: 'You can still start a new private duel.',
            isActive: false,
            action: AppButton(
              label: 'New private duel',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.small,
              onPressed: newDuel,
            ),
          ),
        };
        return _Panel(
          content: content,
          error: failure == null ? null : _failureText(failure),
        );
      },
    );
  }
}

final class _PanelContent {
  const _PanelContent({
    required this.title,
    required this.message,
    this.expiresAt,
    this.action,
    this.isActive = true,
  });

  final String title;
  final String message;
  final DateTime? expiresAt;
  final Component? action;

  /// Blue outlined while a rematch can still happen.
  final bool isActive;
}

final class _Panel extends StatelessComponent {
  const _Panel({required this.content, required this.error});

  final _PanelContent content;
  final String? error;

  @override
  Component build(BuildContext context) {
    final DateTime? expiresAt = content.expiresAt;
    final Component? action = content.action;
    final String? error = this.error;
    return div(
      classes: content.isActive ? 'rematch-panel rematch-panel--active' : 'rematch-panel',
      <Component>[
        div(classes: 'rematch-panel__header', <Component>[
          div(classes: 'rematch-panel__text', <Component>[
            p(classes: 'rematch-panel__title', <Component>[Component.text(content.title)]),
            p(
              classes: 'rematch-panel__message',
              attributes: const <String, String>{'aria-live': 'polite'},
              <Component>[Component.text(content.message)],
            ),
          ]),
          if (expiresAt != null) _CountdownRing(expiresAt: expiresAt),
        ]),
        div(classes: 'rematch-panel__actions', <Component>[?action, const _BackHomeLink()]),
        if (error != null) AppInlineError(error),
      ],
    );
  }
}

/// Seconds left of the rematch window in a 56 px ring.
final class _CountdownRing extends StatelessComponent {
  const _CountdownRing({required this.expiresAt});

  final DateTime expiresAt;

  @override
  Component build(BuildContext context) {
    return div(classes: 'rematch-panel__ring', <Component>[
      AppCountdownText(
        target: expiresAt,
        format: AppCountdownFormat.seconds,
        style: AppTextStyles.monoBodyLg.combine(
          const Styles(
            color: AppColors.primary,
            fontSize: Unit.pixels(17),
            lineHeight: Unit.pixels(20),
          ),
        ),
      ),
    ]);
  }
}

/// The borderless "Back to home" button next to the rematch action.
final class _BackHomeLink extends StatelessComponent {
  const _BackHomeLink();

  @override
  Component build(BuildContext context) {
    return AppTappable(
      onTap: context.goHome,
      radius: 10,
      classes: 'rematch-panel__home',
      child: const span(<Component>[Component.text('Back to home')]),
    );
  }
}

@css
List<StyleRule> get rematchPanelStyles => <StyleRule>[
  css('.rematch-panel').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(22)),
    radius: const BorderRadius.circular(Unit.pixels(16)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(14)),
    backgroundColor: AppColors.surface,
  ),
  css('.rematch-panel--active').styles(
    padding: const Padding.all(Unit.pixels(20)),
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(2)),
    backgroundColor: AppColors.primarySurface,
  ),
  css('.rematch-panel__header').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.rematch-panel__text').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(4)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.rematch-panel__title').combine(AppTextStyles.titleMd),
  css('.rematch-panel__message')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(18))),
  css('.rematch-panel--active .rematch-panel__message').styles(color: AppColors.primaryInk),
  css('.rematch-panel__ring').styles(
    display: Display.flex,
    width: const Unit.pixels(56),
    height: const Unit.pixels(56),
    boxSizing: BoxSizing.borderBox,
    border: Border.all(color: AppColors.primaryLine, width: const Unit.pixels(4)),
    radius: const BorderRadius.circular(Unit.percent(50)),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    flex: const Flex(shrink: 0),
  ),
  css('.rematch-panel__actions').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
  ),
  css('.rematch-panel__home')
      .styles(
        display: Display.inlineFlex,
        height: const Unit.pixels(44),
        padding: const Padding.symmetric(horizontal: Unit.pixels(18)),
        justifyContent: JustifyContent.center,
        alignItems: AlignItems.center,
        flex: const Flex(shrink: 0),
      )
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
];
