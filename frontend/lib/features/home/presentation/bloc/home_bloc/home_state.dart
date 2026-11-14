part of 'home_bloc.dart';

final class HomeState extends Equatable {
  const HomeState({
    this.loadStatus = LoadStatus.initial,
    this.failure,
    this.disciplines = const <DisciplineEntity>[],
    this.ranks,
    this.statistics,
    this.season,
    this.activity = ActivityEntity.none,
    this.selectedCode,
    this.joinStatus = LoadStatus.initial,
    this.joinFailure,
    this.joinedBattleId,
  });

  final LoadStatus loadStatus;
  final Failure? failure;
  final List<DisciplineEntity> disciplines;
  final RankLadderEntity? ranks;
  final StatisticsEntity? statistics;

  /// Current season for the page eyebrow; `null` when it failed to load.
  final SeasonEntity? season;
  final ActivityEntity activity;
  final String? selectedCode;
  final LoadStatus joinStatus;
  final Failure? joinFailure;
  final String? joinedBattleId;

  bool get hasContent => statistics != null && disciplines.isNotEmpty;

  DisciplineEntity? get selected {
    for (final DisciplineEntity discipline in disciplines) {
      if (discipline.code == selectedCode) return discipline;
    }
    return null;
  }

  HomeState copyWith({
    LoadStatus? loadStatus,
    Failure? failure,
    List<DisciplineEntity>? disciplines,
    RankLadderEntity? ranks,
    StatisticsEntity? statistics,
    SeasonEntity? season,
    ActivityEntity? activity,
    String? selectedCode,
    LoadStatus? joinStatus,
    Failure? joinFailure,
    String? joinedBattleId,
    bool resetFailure = false,
    bool resetJoinFailure = false,
  }) {
    return HomeState(
      loadStatus: loadStatus ?? this.loadStatus,
      failure: resetFailure ? null : failure ?? this.failure,
      disciplines: disciplines ?? this.disciplines,
      ranks: ranks ?? this.ranks,
      statistics: statistics ?? this.statistics,
      season: season ?? this.season,
      activity: activity ?? this.activity,
      selectedCode: selectedCode ?? this.selectedCode,
      joinStatus: joinStatus ?? this.joinStatus,
      joinFailure: resetJoinFailure ? null : joinFailure ?? this.joinFailure,
      joinedBattleId: joinedBattleId ?? this.joinedBattleId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    failure,
    disciplines,
    ranks,
    statistics,
    season,
    activity,
    selectedCode,
    joinStatus,
    joinFailure,
    joinedBattleId,
  ];
}
