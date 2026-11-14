import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/extensions/play_failure_message.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_status.dart';
import 'package:skill_battles/features/battle_result/presentation/bloc/battle_result_bloc/battle_result_bloc.dart';

/// Rematch after a private duel: one click only asks; the new duel starts
/// when both agreed within 60 s, and both pass Ready again.
final class RematchPanel extends StatelessWidget {
  const RematchPanel({
    required this.myUserId,
    required this.opponentNickname,
    super.key,
  });

  final String myUserId;
  final String opponentNickname;

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
        final TextStyle body = AppTextStyles.bodyMd.copyWith(
          color: AppColors.inkSoft,
        );
        final Widget content = switch (rematch) {
          null => Row(
            spacing: 16,
            children: <Widget>[
              Expanded(
                child: Text('Play $opponentNickname again?', style: body),
              ),
              AppButton(
                label: busy ? 'Asking…' : 'Ask for a rematch',
                variant: AppButtonVariant.dark,
                size: AppButtonSize.small,
                onPressed: busy
                    ? null
                    : () => bloc.add(const BattleResultRematchRequested()),
              ),
            ],
          ),
          RematchEntity(status: RematchStatus.waiting)
              when rematch.hasConsentOf(myUserId) =>
            Row(
              spacing: 12,
              children: <Widget>[
                Expanded(
                  child: Text('Waiting for $opponentNickname…', style: body),
                ),
                AppCountdownText(
                  target: rematch.expiresAt,
                  style: AppTextStyles.monoBodyMd,
                ),
                AppTextLink(
                  label: 'Cancel',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                  onPressed: busy
                      ? null
                      : () => bloc.add(const BattleResultRematchCancelled()),
                ),
              ],
            ),
          RematchEntity(status: RematchStatus.waiting) => Row(
            spacing: 12,
            children: <Widget>[
              Expanded(
                child: Text('$opponentNickname wants a rematch.', style: body),
              ),
              AppCountdownText(
                target: rematch.expiresAt,
                style: AppTextStyles.monoBodyMd,
              ),
              AppButton(
                label: busy ? 'Joining…' : 'Accept',
                size: AppButtonSize.small,
                onPressed: busy
                    ? null
                    : () => bloc.add(const BattleResultRematchRequested()),
              ),
            ],
          ),
          RematchEntity(status: RematchStatus.matched) => Text(
            'Rematch on — opening the ready check…',
            style: body,
          ),
          RematchEntity(status: RematchStatus.expired) => Text(
            'The rematch request expired.',
            style: body.copyWith(color: AppColors.muted),
          ),
          RematchEntity(status: RematchStatus.cancelled) => Text(
            'The rematch was cancelled.',
            style: body.copyWith(color: AppColors.muted),
          ),
        };
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: <Widget>[
                content,
                if (failure != null) AppInlineError(_failureText(failure)),
              ],
            ),
          ),
        );
      },
    );
  }
}
