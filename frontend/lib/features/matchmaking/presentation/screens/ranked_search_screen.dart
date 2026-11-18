import 'dart:async';
import 'dart:math' as math;

import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/extensions/play_failure_message.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_tag.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
import 'package:skill_battles/core/utils/feature_flags.dart';
import 'package:skill_battles/features/account/domain/usecases/get_statistics_usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_entry_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_status.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/cancel_queue_entry_usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/get_queue_entry_usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/join_queue_usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/watch_queue_entry_usecase.dart';
import 'package:skill_battles/features/matchmaking/presentation/bloc/ranked_search_bloc/ranked_search_bloc.dart';

/// Ranked matchmaking (Paper: "03 Ranked Search"). Joining checks the quota;
/// the attempt is used only when the first question opens.
final class RankedSearchScreen extends StatelessComponent implements RouteWrapper {
  const RankedSearchScreen({this.disciplineCode, this.entryId, super.key});

  final String? disciplineCode;

  /// Resumes an existing entry (activity recovery).
  final String? entryId;

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocSignalProvider<RankedSearchBloc>(
      create: (_) => RankedSearchBloc(
        joinQueue: dependencies.getDep<JoinQueueUsecase>(),
        getEntry: dependencies.getDep<GetQueueEntryUsecase>(),
        cancelEntry: dependencies.getDep<CancelQueueEntryUsecase>(),
        watchEntry: dependencies.getDep<WatchQueueEntryUsecase>(),
        watchConnection: dependencies.getDep<WatchConnectionUsecase>(),
        getStatistics: dependencies.getDep<GetStatisticsUsecase>(),
      )..add(RankedSearchStarted(disciplineCode: disciplineCode, entryId: entryId)),
      child: this,
    );
  }

  @override
  Component build(BuildContext context) {
    return MultiBlocSignalListener(
      listeners: <BlocSignalListenerSingleChildComponent>[
        BlocSignalListener<RankedSearchBloc, RankedSearchState>(
          listenWhen: (RankedSearchState previous, RankedSearchState current) =>
              previous.battleId != current.battleId && current.battleId != null,
          listener: (BuildContext context, RankedSearchState state) => context.goBattle(state.battleId!),
        ),
        BlocSignalListener<RankedSearchBloc, RankedSearchState>(
          listenWhen: (RankedSearchState previous, RankedSearchState current) =>
              previous.cancelStatus != current.cancelStatus && current.cancelStatus.isSuccess,
          listener: (BuildContext context, RankedSearchState state) => context.goHome(),
        ),
      ],
      child: AppDesktopViewport(
        child: BlocSignalBuilder<RankedSearchBloc, RankedSearchState>(
          builder: (BuildContext context, RankedSearchState state) {
            final String code = state.disciplineCode ?? disciplineCode ?? '';
            return div(classes: 'ranked-search', <Component>[
              _Heading(disciplineCode: code, state: state),
              switch (state.status) {
                RankedSearchStatus.failure => _JoinFailure(failure: state.failure, disciplineCode: code),
                RankedSearchStatus.ended => _Ended(entry: state.entry, disciplineCode: code),
                _ => _Searching(state: state),
              },
            ]);
          },
        ),
      ),
    );
  }
}

final class _Heading extends StatelessComponent {
  const _Heading({required this.disciplineCode, required this.state});

  final String disciplineCode;
  final RankedSearchState state;

  @override
  Component build(BuildContext context) {
    final String title = switch (state.status) {
      RankedSearchStatus.matched => 'Opponent found',
      RankedSearchStatus.ended => 'Search ended',
      RankedSearchStatus.failure => "Can't start a ranked match",
      _ => 'Looking for an opponent',
    };
    return div(classes: 'ranked-search__heading', <Component>[
      AppEyebrow('${formatDisciplineCode(disciplineCode)} · Ranked', color: AppColors.primary),
      h1(
        classes: 'ranked-search__title',
        attributes: const <String, String>{'aria-live': 'polite'},
        <Component>[Component.text(title)],
      ),
    ]);
  }
}

final class _Searching extends StatelessComponent {
  const _Searching({required this.state});

  final RankedSearchState state;

  @override
  Component build(BuildContext context) {
    final QueueEntryEntity? entry = state.entry;
    final bool matched = state.status == RankedSearchStatus.matched;
    final Failure? cancelFailure = state.cancelFailure;
    return div(classes: 'ranked-search__searching', <Component>[
      _SearchRings(label: matched ? 'Go!' : null, since: entry?.createdAt),
      div(classes: 'ranked-search__details', <Component>[
        if (entry != null && !matched)
          _RatingRange(window: entry.ratingWindow, rating: state.rating)
        else
          p(classes: 'ranked-search__muted', <Component>[
            Component.text(matched ? 'Opening the ready check…' : 'Joining the queue…'),
          ]),
        if (cancelFailure != null) AppInlineError(cancelFailure.userMessage),
        if (!matched)
          AppButton(
            label: state.cancelStatus.isLoading ? 'Cancelling…' : 'Cancel search',
            variant: AppButtonVariant.outline,
            size: AppButtonSize.medium,
            onPressed: state.cancelStatus.isLoading
                ? null
                : () => context.read<RankedSearchBloc>().add(const RankedSearchCancelRequested()),
          ),
      ]),
    ]);
  }
}

/// "Rating range [984 – 1384] · widening while you wait"; "± 200" until the
/// own rating is known.
final class _RatingRange extends StatelessComponent {
  const _RatingRange({required this.window, required this.rating});

  final int window;
  final int? rating;

  @override
  Component build(BuildContext context) {
    final int? rating = this.rating;
    return div(classes: 'ranked-search__range', <Component>[
      p(classes: 'ranked-search__muted', <Component>[
        Component.text(rating == null ? 'Rating window' : 'Rating range'),
      ]),
      AppTag(
        label: rating == null ? '± $window' : '${math.max(0, rating - window)} – ${rating + window}',
        tone: AppTagTone.neutral,
        padding: const Padding.symmetric(horizontal: Unit.pixels(10), vertical: Unit.pixels(4)),
        style: AppTextStyles.monoBodyMd,
      ),
      const p(classes: 'ranked-search__muted', <Component>[Component.text('· widening while you wait')]),
    ]);
  }
}

final class _JoinFailure extends StatelessComponent {
  const _JoinFailure({required this.failure, required this.disciplineCode});

  final Failure? failure;
  final String disciplineCode;

  @override
  Component build(BuildContext context) {
    final Failure? failure = this.failure;
    final bool isLimit = failure?.isDailyLimit ?? false;
    if (isLimit && !FeatureFlags.billing) {
      return _LimitOutcome(message: failure!.playMessage(DateTime.now()), disciplineCode: disciplineCode);
    }
    return _Outcome(
      message: failure?.playMessage(DateTime.now()) ?? 'Choose a discipline on the home screen first.',
      primaryLabel: isLimit ? 'See Pro plans' : 'Try again',
      onPrimary: isLimit
          ? context.goPro
          : disciplineCode.isEmpty
          ? null
          : () => context.read<RankedSearchBloc>().add(RankedSearchStarted(disciplineCode: disciplineCode)),
      secondaryLabel: isLimit ? 'Play a private duel' : 'Back to home',
      onSecondary: isLimit && disciplineCode.isNotEmpty
          ? () => context.goPrivateDuel(disciplineCode: disciplineCode)
          : context.goHome,
    );
  }
}

final class _Ended extends StatelessComponent {
  const _Ended({required this.entry, required this.disciplineCode});

  final QueueEntryEntity? entry;
  final String disciplineCode;

  @override
  Component build(BuildContext context) {
    final ApiFailure? error = entry?.error;
    final bool expired = entry?.status == QueueStatus.expired;
    final bool isLimit = error?.isDailyLimit ?? false;
    if (isLimit && !FeatureFlags.billing) {
      return _LimitOutcome(message: error!.playMessage(DateTime.now()), disciplineCode: disciplineCode);
    }
    return _Outcome(
      message: error != null
          ? error.playMessage(DateTime.now())
          : expired
          ? 'No opponent was found in time. Try again in a moment.'
          : 'The search was cancelled.',
      primaryLabel: isLimit ? 'See Pro plans' : 'Search again',
      onPrimary: isLimit
          ? context.goPro
          : () => context.read<RankedSearchBloc>().add(RankedSearchStarted(disciplineCode: disciplineCode)),
      secondaryLabel: 'Back to home',
      onSecondary: context.goHome,
    );
  }
}

/// The daily ranked limit without billing: the way on is a private duel.
final class _LimitOutcome extends StatelessComponent {
  const _LimitOutcome({required this.message, required this.disciplineCode});

  final String message;
  final String disciplineCode;

  @override
  Component build(BuildContext context) {
    return _Outcome(
      message: message,
      primaryLabel: 'Play a private duel',
      onPrimary: disciplineCode.isEmpty ? null : () => context.goPrivateDuel(disciplineCode: disciplineCode),
      secondaryLabel: 'Back to home',
      onSecondary: context.goHome,
    );
  }
}

final class _Outcome extends StatelessComponent {
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
  Component build(BuildContext context) {
    return div(classes: 'ranked-search__outcome', <Component>[
      p(classes: 'ranked-search__message', <Component>[Component.text(message)]),
      div(classes: 'ranked-search__actions', <Component>[
        AppButton(label: primaryLabel, size: AppButtonSize.medium, onPressed: onPrimary),
        AppButton(
          label: secondaryLabel,
          variant: AppButtonVariant.outline,
          size: AppButtonSize.medium,
          onPressed: onSecondary,
        ),
      ]),
    ]);
  }
}

/// Concentric rings with the time since the search started.
final class _SearchRings extends StatelessComponent {
  const _SearchRings({required this.since, this.label});

  final DateTime? since;
  final String? label;

  @override
  Component build(BuildContext context) {
    final String? label = this.label;
    final DateTime? since = this.since;
    return div(classes: 'ranked-search__rings', <Component>[
      div(classes: 'ranked-search__ring ranked-search__ring--outer', <Component>[
        div(classes: 'ranked-search__ring ranked-search__ring--middle', <Component>[
          div(classes: 'ranked-search__ring ranked-search__ring--inner', <Component>[
            if (label != null)
              span(classes: 'ranked-search__time', <Component>[Component.text(label)])
            else if (since == null)
              const span(classes: 'ranked-search__time', <Component>[Component.text('0:00')])
            else
              _Elapsed(since: since),
          ]),
        ]),
      ]),
    ]);
  }
}

final class _Elapsed extends StatefulComponent {
  const _Elapsed({required this.since});

  final DateTime since;

  @override
  State<_Elapsed> createState() => _ElapsedState();
}

final class _ElapsedState extends State<_Elapsed> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final Duration elapsed = DateTime.now().difference(component.since.toLocal());
    final int seconds = elapsed.isNegative ? 0 : elapsed.inSeconds;
    return span(classes: 'ranked-search__time', <Component>[
      Component.text('${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'),
    ]);
  }
}

@css
List<StyleRule> get rankedSearchScreenStyles => <StyleRule>[
  css('.ranked-search').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(32)),
  ),
  css('.ranked-search__heading').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(10)),
  ),
  css('.ranked-search__title')
      .combine(AppTextStyles.displaySm)
      .combine(const Styles(textAlign: TextAlign.center, lineHeight: Unit.pixels(54))),
  css('.ranked-search__searching').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(32)),
  ),
  css('.ranked-search__details').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(20)),
  ),
  css('.ranked-search__muted').combine(AppTextStyles.bodyMd).combine(const Styles(color: AppColors.muted)),
  css('.ranked-search__range').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.ranked-search__outcome').styles(
    display: Display.flex,
    maxWidth: const Unit.pixels(520),
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(24)),
  ),
  css('.ranked-search__message')
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(color: AppColors.inkSoft, textAlign: TextAlign.center, lineHeight: Unit.pixels(22))),
  css('.ranked-search__actions').styles(
    display: Display.flex,
    flexWrap: FlexWrap.wrap,
    justifyContent: JustifyContent.center,
    gap: const Gap.all(Unit.pixels(12)),
  ),
  css('.ranked-search__rings').styles(padding: const Padding.symmetric(vertical: Unit.pixels(8))),
  css('.ranked-search__ring').styles(
    display: Display.flex,
    radius: const BorderRadius.circular(Unit.percent(50)),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
  ),
  css('.ranked-search__ring--outer').styles(
    width: const Unit.pixels(320),
    height: const Unit.pixels(320),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
  ),
  css('.ranked-search__ring--middle').styles(
    width: const Unit.pixels(250),
    height: const Unit.pixels(250),
    border: Border.all(color: AppColors.primaryRing, width: const Unit.pixels(1)),
  ),
  css('.ranked-search__ring--inner').styles(
    width: const Unit.pixels(184),
    height: const Unit.pixels(184),
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(2)),
    backgroundColor: AppColors.primarySurface,
  ),
  css('.ranked-search__time').combine(AppTextStyles.monoXxl).combine(const Styles(color: AppColors.primary)),
];
