import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

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
final class RematchPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocBuilder<BattleResultBloc, BattleResultState>(
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
          RematchEntity(status: RematchStatus.waiting)
              when rematch.hasConsentOf(myUserId) =>
            _PanelContent(
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
  final Widget? action;

  /// Blue outlined while a rematch can still happen.
  final bool isActive;
}

final class _Panel extends StatelessWidget {
  const _Panel({required this.content, required this.error});

  final _PanelContent content;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final DateTime? expiresAt = content.expiresAt;
    final Widget? action = content.action;
    final String? error = this.error;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: content.isActive ? AppColors.primarySurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: content.isActive
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(content.isActive ? 20 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: <Widget>[
            Row(
              spacing: 16,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: <Widget>[
                      Text(content.title, style: AppTextStyles.titleMd),
                      Text(
                        content.message,
                        style: AppTextStyles.bodySm.copyWith(
                          height: 18 / 13,
                          color: content.isActive
                              ? AppColors.primaryInk
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (expiresAt != null) _CountdownRing(expiresAt: expiresAt),
              ],
            ),
            Row(
              spacing: 10,
              children: <Widget>[?action, const _BackHomeLink()],
            ),
            if (error != null) AppInlineError(error),
          ],
        ),
      ),
    );
  }
}

/// Seconds left of the rematch window in a 56 px ring.
final class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.expiresAt});

  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryLine, width: 4),
      ),
      child: AppCountdownText(
        target: expiresAt,
        format: AppCountdownFormat.seconds,
        style: AppTextStyles.monoBodyLg.copyWith(
          fontSize: 17,
          height: 20 / 17,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// The borderless "Back to home" button next to the rematch action.
final class _BackHomeLink extends StatelessWidget {
  const _BackHomeLink();

  @override
  Widget build(BuildContext context) {
    return AppTappable(
      onTap: context.goHome,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Center(
            widthFactor: 1,
            child: Text(
              'Back to home',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
