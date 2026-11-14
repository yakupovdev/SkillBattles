import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/core/presentation/widgets/app_segmented_control.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/presentation/widgets/app_tag.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_disciplines_usecase.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entry_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/usecases/get_leaderboard_usecase.dart';
import 'package:skill_battles/features/leaderboard/presentation/bloc/leaderboard_bloc/leaderboard_bloc.dart';

/// Current-season leaderboard per discipline: top 50 and your own row.
/// Positions are unique; PRO is only a badge.
final class LeaderboardScreen extends StatelessWidget
    implements GoRouterWrapper {
  const LeaderboardScreen({this.disciplineCode, super.key});

  final String? disciplineCode;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<LeaderboardBloc>(
      create: (_) => LeaderboardBloc(
        getDisciplines: dependencies.getDep<GetDisciplinesUsecase>(),
        getLeaderboard: dependencies.getDep<GetLeaderboardUsecase>(),
      )..add(LeaderboardStarted(disciplineCode: disciplineCode)),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDesktopViewport(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
        child: BlocBuilder<LeaderboardBloc, LeaderboardState>(
          builder: (BuildContext context, LeaderboardState state) {
            final LeaderboardEntity? board = state.board;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 24,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: <Widget>[
                          AppEyebrow(
                            board == null
                                ? 'Season leaderboard'
                                : '${board.season.name} · ends '
                                      '${DisplayFormatters.date(board.season.endsAt)}',
                          ),
                          const Text(
                            'Leaderboard',
                            style: AppTextStyles.displayMd,
                          ),
                        ],
                      ),
                    ),
                    if (state.disciplines.length > 1)
                      AppSegmentedControl<String>(
                        size: AppSegmentedControlSize.small,
                        selected: state.selectedCode ?? '',
                        onSelected: (String code) => context
                            .read<LeaderboardBloc>()
                            .add(LeaderboardDisciplineSelected(code)),
                        segments: <AppSegment<String>>[
                          for (final DisciplineEntity d in state.disciplines)
                            AppSegment<String>(
                              value: d.code,
                              label: d.displayName,
                            ),
                        ],
                      ),
                  ],
                ),
                if (board == null && state.boardStatus.isFailure)
                  AppErrorView(
                    message: state.failure?.userMessage ?? '',
                    onRetry: state.selectedCode == null
                        ? () => context.read<LeaderboardBloc>().add(
                            LeaderboardStarted(disciplineCode: disciplineCode),
                          )
                        : () => context.read<LeaderboardBloc>().add(
                            LeaderboardDisciplineSelected(state.selectedCode!),
                          ),
                  )
                else if (board == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _Board(board: board),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _Board extends StatelessWidget {
  const _Board({required this.board});

  final LeaderboardEntity board;

  @override
  Widget build(BuildContext context) {
    final LeaderboardEntryEntity? me = board.me;
    final bool meInTop =
        me != null &&
        board.top.any(
          (LeaderboardEntryEntity e) => e.player.id == me.player.id,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: <Widget>[
        if (me == null)
          const AppNotice(
            message:
                "You'll appear here once your rating for this season is ready "
                '(finish any match from the previous season first).',
            tone: AppNoticeTone.warning,
          )
        else if (!meInTop) ...<Widget>[
          const AppEyebrow('Your position'),
          _Row(entry: me, isMe: true),
        ],
        const _Header(),
        if (board.top.isEmpty)
          const AppEmptyView(
            title: 'No ratings yet',
            message: 'Play a ranked match to open the season.',
          ),
        for (final LeaderboardEntryEntity entry in board.top)
          _Row(
            key: ValueKey<String>(entry.player.id),
            entry: entry,
            isMe: entry.player.id == me?.player.id,
          ),
        Text(
          'Updated ${DisplayFormatters.time(board.generatedAt)} · ties are '
          'broken by who reached the rating first.',
          style: AppTextStyles.bodyXs.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.bodyXs.copyWith(
      fontWeight: FontWeight.w500,
      color: AppColors.muted,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          spacing: 16,
          children: <Widget>[
            SizedBox(width: 48, child: Text('#', style: style)),
            Expanded(child: Text('Player', style: style)),
            SizedBox(width: 160, child: Text('Rank', style: style)),
            SizedBox(
              width: 100,
              child: Text('Rating', style: style, textAlign: TextAlign.right),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.isMe, super.key});

  final LeaderboardEntryEntity entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isMe ? AppColors.primarySurface : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          spacing: 16,
          children: <Widget>[
            SizedBox(
              width: 48,
              child: Text(
                '${entry.position}',
                style: AppTextStyles.monoBodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: entry.position <= 3
                      ? AppColors.accentText
                      : AppColors.ink,
                ),
              ),
            ),
            Expanded(
              child: Row(
                spacing: 10,
                children: <Widget>[
                  AppAvatar(
                    nickname: entry.player.nickname,
                    size: AppAvatarSize.xs,
                    tone: isMe ? AppAvatarTone.primary : AppAvatarTone.accent,
                  ),
                  Flexible(
                    child: Text(
                      isMe
                          ? '${entry.player.nickname} (you)'
                          : entry.player.nickname,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (entry.player.isPro) const ProBadge(compact: true),
                  if (entry.isCalibrating)
                    AppTag(
                      label: 'Calibrating',
                      tone: AppTagTone.neutral,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      style: AppTextStyles.bodyXs.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 160,
              child: Text(
                formatRankCode(entry.rankCode),
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                '${entry.rating}',
                style: AppTextStyles.monoBodyMd,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
