part of 'profile_bloc.dart';

final class ProfileState extends Equatable {
  const ProfileState({
    this.loadStatus = LoadStatus.initial,
    this.failure,
    this.statistics,
    this.disciplines = const <DisciplineEntity>[],
    this.ranks,
    this.seasons,
    this.selectedCode,
    this.historyStatus = LoadStatus.initial,
    this.history,
    this.historyFailure,
    this.historyParams = const HistoryParamsEntity(
      size: ProfileBloc.historyPageSize,
    ),
  });

  final LoadStatus loadStatus;
  final Failure? failure;
  final StatisticsEntity? statistics;
  final List<DisciplineEntity> disciplines;
  final RankLadderEntity? ranks;
  final SeasonHistoryPageEntity? seasons;
  final String? selectedCode;
  final LoadStatus historyStatus;
  final HistoryPageEntity? history;
  final Failure? historyFailure;
  final HistoryParamsEntity historyParams;

  ProfileState copyWith({
    LoadStatus? loadStatus,
    Failure? failure,
    StatisticsEntity? statistics,
    List<DisciplineEntity>? disciplines,
    RankLadderEntity? ranks,
    SeasonHistoryPageEntity? seasons,
    String? selectedCode,
    LoadStatus? historyStatus,
    HistoryPageEntity? history,
    Failure? historyFailure,
    HistoryParamsEntity? historyParams,
    bool resetFailure = false,
    bool resetHistoryFailure = false,
  }) {
    return ProfileState(
      loadStatus: loadStatus ?? this.loadStatus,
      failure: resetFailure ? null : failure ?? this.failure,
      statistics: statistics ?? this.statistics,
      disciplines: disciplines ?? this.disciplines,
      ranks: ranks ?? this.ranks,
      seasons: seasons ?? this.seasons,
      selectedCode: selectedCode ?? this.selectedCode,
      historyStatus: historyStatus ?? this.historyStatus,
      history: history ?? this.history,
      historyFailure: resetHistoryFailure
          ? null
          : historyFailure ?? this.historyFailure,
      historyParams: historyParams ?? this.historyParams,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    failure,
    statistics,
    disciplines,
    ranks,
    seasons,
    selectedCode,
    historyStatus,
    history,
    historyFailure,
    historyParams,
  ];
}
