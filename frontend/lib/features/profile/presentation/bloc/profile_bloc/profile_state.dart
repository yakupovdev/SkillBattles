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
  });

  final LoadStatus loadStatus;
  final Failure? failure;
  final StatisticsEntity? statistics;
  final List<DisciplineEntity> disciplines;
  final RankLadderEntity? ranks;
  final SeasonHistoryPageEntity? seasons;
  final String? selectedCode;

  ProfileState copyWith({
    LoadStatus? loadStatus,
    Failure? failure,
    StatisticsEntity? statistics,
    List<DisciplineEntity>? disciplines,
    RankLadderEntity? ranks,
    SeasonHistoryPageEntity? seasons,
    String? selectedCode,
    bool resetFailure = false,
  }) {
    return ProfileState(
      loadStatus: loadStatus ?? this.loadStatus,
      failure: resetFailure ? null : failure ?? this.failure,
      statistics: statistics ?? this.statistics,
      disciplines: disciplines ?? this.disciplines,
      ranks: ranks ?? this.ranks,
      seasons: seasons ?? this.seasons,
      selectedCode: selectedCode ?? this.selectedCode,
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
  ];
}
