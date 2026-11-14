import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/extensions/play_failure_message.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_tag.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_entry_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_status.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/cancel_queue_entry_usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/get_queue_entry_usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/join_queue_usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/watch_queue_entry_usecase.dart';
import 'package:skill_battles/features/matchmaking/presentation/bloc/ranked_search_bloc/ranked_search_bloc.dart';

/// Ranked matchmaking (Paper: "03 Ranked Search"). Joining checks the quota;
/// the attempt is used only when the first question opens.
final class RankedSearchScreen extends StatelessWidget
    implements GoRouterWrapper {
  const RankedSearchScreen({this.disciplineCode, this.entryId, super.key});

  final String? disciplineCode;

  /// Resumes an existing entry (activity recovery).
  final String? entryId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<RankedSearchBloc>(
      create: (_) =>
          RankedSearchBloc(
            joinQueue: dependencies.getDep<JoinQueueUsecase>(),
            getEntry: dependencies.getDep<GetQueueEntryUsecase>(),
            cancelEntry: dependencies.getDep<CancelQueueEntryUsecase>(),
            watchEntry: dependencies.getDep<WatchQueueEntryUsecase>(),
            watchConnection: dependencies.getDep<WatchConnectionUsecase>(),
          )..add(
            RankedSearchStarted(
              disciplineCode: disciplineCode,
              entryId: entryId,
            ),
          ),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<RankedSearchBloc, RankedSearchState>>[
        BlocListener<RankedSearchBloc, RankedSearchState>(
          listenWhen: (RankedSearchState previous, RankedSearchState current) =>
              previous.battleId != current.battleId && current.battleId != null,
          listener: (BuildContext context, RankedSearchState state) =>
              context.goBattle(state.battleId!),
        ),
        BlocListener<RankedSearchBloc, RankedSearchState>(
          listenWhen: (RankedSearchState previous, RankedSearchState current) =>
              previous.cancelStatus != current.cancelStatus &&
              current.cancelStatus.isSuccess,
          listener: (BuildContext context, RankedSearchState state) =>
              context.goHome(),
        ),
      ],
      child: AppDesktopViewport(
        child: BlocBuilder<RankedSearchBloc, RankedSearchState>(
          builder: (BuildContext context, RankedSearchState state) {
            final String code = state.disciplineCode ?? disciplineCode ?? '';
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 32,
              children: <Widget>[
                _Heading(disciplineCode: code, state: state),
                switch (state.status) {
                  RankedSearchStatus.failure => _JoinFailure(
                    failure: state.failure,
                    disciplineCode: code,
                  ),
                  RankedSearchStatus.ended => _Ended(
                    entry: state.entry,
                    disciplineCode: code,
                  ),
                  _ => _Searching(state: state),
                },
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _Heading extends StatelessWidget {
  const _Heading({required this.disciplineCode, required this.state});

  final String disciplineCode;
  final RankedSearchState state;

  @override
  Widget build(BuildContext context) {
    final String title = switch (state.status) {
      RankedSearchStatus.matched => 'Opponent found',
      RankedSearchStatus.ended => 'Search ended',
      RankedSearchStatus.failure => "Can't start a ranked match",
      _ => 'Looking for an opponent',
    };
    return Column(
      spacing: 10,
      children: <Widget>[
        AppEyebrow(
          '${formatDisciplineCode(disciplineCode)} · Ranked',
          color: AppColors.primary,
        ),
        Text(
          title,
          style: AppTextStyles.displaySm.copyWith(height: 54 / 44),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

final class _Searching extends StatelessWidget {
  const _Searching({required this.state});

  final RankedSearchState state;

  @override
  Widget build(BuildContext context) {
    final QueueEntryEntity? entry = state.entry;
    final TextStyle muted = AppTextStyles.bodyMd.copyWith(
      color: AppColors.muted,
    );
    final bool matched = state.status == RankedSearchStatus.matched;
    final Failure? cancelFailure = state.cancelFailure;
    return Column(
      spacing: 28,
      children: <Widget>[
        _SearchRings(
          label: entry == null
              ? null
              : matched
              ? 'Go!'
              : null,
          since: entry?.createdAt,
        ),
        if (entry != null && !matched)
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Text('Rating window', style: muted),
              AppTag(
                label: '± ${entry.ratingWindow}',
                tone: AppTagTone.neutral,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                style: AppTextStyles.monoBodyMd,
              ),
              Text('· widens while you wait · gives up in', style: muted),
              AppCountdownText(
                target: entry.expiresAt,
                style: AppTextStyles.monoBodyMd,
              ),
            ],
          )
        else
          Text(
            matched ? 'Opening the ready check…' : 'Joining the queue…',
            style: muted,
          ),
        if (cancelFailure != null) AppInlineError(cancelFailure.userMessage),
        if (!matched)
          AppButton(
            label: state.cancelStatus.isLoading
                ? 'Cancelling…'
                : 'Cancel search',
            variant: AppButtonVariant.outline,
            size: AppButtonSize.medium,
            onPressed: state.cancelStatus.isLoading
                ? null
                : () => context.read<RankedSearchBloc>().add(
                    const RankedSearchCancelRequested(),
                  ),
          ),
      ],
    );
  }
}

final class _JoinFailure extends StatelessWidget {
  const _JoinFailure({required this.failure, required this.disciplineCode});

  final Failure? failure;
  final String disciplineCode;

  @override
  Widget build(BuildContext context) {
    final Failure? failure = this.failure;
    final bool isLimit = failure?.isDailyLimit ?? false;
    return _Outcome(
      message:
          failure?.playMessage(DateTime.now()) ??
          'Choose a discipline on the home screen first.',
      primaryLabel: isLimit ? 'See Pro plans' : 'Try again',
      onPrimary: isLimit
          ? context.goPro
          : disciplineCode.isEmpty
          ? null
          : () => context.read<RankedSearchBloc>().add(
              RankedSearchStarted(disciplineCode: disciplineCode),
            ),
      secondaryLabel: isLimit ? 'Play a private duel' : 'Back to home',
      onSecondary: isLimit && disciplineCode.isNotEmpty
          ? () => context.goPrivateDuel(disciplineCode: disciplineCode)
          : context.goHome,
    );
  }
}

final class _Ended extends StatelessWidget {
  const _Ended({required this.entry, required this.disciplineCode});

  final QueueEntryEntity? entry;
  final String disciplineCode;

  @override
  Widget build(BuildContext context) {
    final ApiFailure? error = entry?.error;
    final bool expired = entry?.status == QueueStatus.expired;
    final bool isLimit = error?.isDailyLimit ?? false;
    return _Outcome(
      message: error != null
          ? error.playMessage(DateTime.now())
          : expired
          ? 'No opponent was found in time. Try again in a moment.'
          : 'The search was cancelled.',
      primaryLabel: isLimit ? 'See Pro plans' : 'Search again',
      onPrimary: isLimit
          ? context.goPro
          : () => context.read<RankedSearchBloc>().add(
              RankedSearchStarted(disciplineCode: disciplineCode),
            ),
      secondaryLabel: 'Back to home',
      onSecondary: context.goHome,
    );
  }
}

final class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String message;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        spacing: 24,
        children: <Widget>[
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLg.copyWith(
              color: AppColors.inkSoft,
              height: 22 / 15,
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: <Widget>[
              AppButton(
                label: primaryLabel,
                size: AppButtonSize.medium,
                onPressed: onPrimary,
              ),
              AppButton(
                label: secondaryLabel,
                variant: AppButtonVariant.outline,
                size: AppButtonSize.medium,
                onPressed: onSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Concentric rings with the time since the search started.
final class _SearchRings extends StatelessWidget {
  const _SearchRings({required this.since, this.label});

  final DateTime? since;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final String? label = this.label;
    final DateTime? since = this.since;
    final TextStyle style = AppTextStyles.monoXxl.copyWith(
      color: AppColors.primary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _Ring(
        diameter: 320,
        color: AppColors.border,
        borderWidth: 1,
        child: _Ring(
          diameter: 250,
          color: AppColors.primaryRing,
          borderWidth: 1,
          child: _Ring(
            diameter: 184,
            color: AppColors.primary,
            borderWidth: 2,
            fill: AppColors.primarySurface,
            child: label != null
                ? Text(label, style: style)
                : since == null
                ? Text('0:00', style: style)
                : _Elapsed(since: since, style: style),
          ),
        ),
      ),
    );
  }
}

final class _Elapsed extends StatefulWidget {
  const _Elapsed({required this.since, required this.style});

  final DateTime since;
  final TextStyle style;

  @override
  State<_Elapsed> createState() => _ElapsedState();
}

final class _ElapsedState extends State<_Elapsed> {
  late final Stream<int> _ticks;

  @override
  void initState() {
    super.initState();
    _ticks = Stream<int>.periodic(const Duration(seconds: 1), (int i) => i);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _ticks,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        final Duration elapsed = DateTime.now().difference(
          widget.since.toLocal(),
        );
        final int seconds = elapsed.isNegative ? 0 : elapsed.inSeconds;
        return Text(
          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
          style: widget.style,
        );
      },
    );
  }
}

final class _Ring extends StatelessWidget {
  const _Ring({
    required this.diameter,
    required this.color,
    required this.borderWidth,
    required this.child,
    this.fill,
  });

  final double diameter;
  final Color color;
  final double borderWidth;
  final Color? fill;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: borderWidth),
      ),
      child: child,
    );
  }
}
