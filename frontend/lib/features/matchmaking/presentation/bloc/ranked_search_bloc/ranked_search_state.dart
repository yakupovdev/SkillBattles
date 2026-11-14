part of 'ranked_search_bloc.dart';

enum RankedSearchStatus { idle, joining, searching, matched, ended, failure }

final class RankedSearchState extends Equatable {
  const RankedSearchState({
    this.status = RankedSearchStatus.idle,
    this.disciplineCode,
    this.entry,
    this.failure,
    this.cancelStatus = LoadStatus.initial,
    this.cancelFailure,
    this.statistics,
  });

  final RankedSearchStatus status;
  final String? disciplineCode;
  final QueueEntryEntity? entry;

  /// Why joining failed (429 with `resetsAt`, activity conflict, …).
  final Failure? failure;
  final LoadStatus cancelStatus;
  final Failure? cancelFailure;

  /// Own ratings; `null` until loaded or when they could not be loaded.
  final StatisticsEntity? statistics;

  /// Own rating in the searched discipline, when known.
  int? get rating {
    final String? code = entry?.disciplineCode ?? disciplineCode;
    return code == null ? null : statistics?.forDiscipline(code)?.rating;
  }

  bool get isOver =>
      status == RankedSearchStatus.matched ||
      status == RankedSearchStatus.ended;

  String? get battleId =>
      status == RankedSearchStatus.matched ? entry?.battleId : null;

  RankedSearchState copyWith({
    RankedSearchStatus? status,
    String? disciplineCode,
    QueueEntryEntity? entry,
    Failure? failure,
    LoadStatus? cancelStatus,
    Failure? cancelFailure,
    StatisticsEntity? statistics,
    bool resetFailure = false,
  }) {
    return RankedSearchState(
      status: status ?? this.status,
      disciplineCode: disciplineCode ?? this.disciplineCode,
      entry: entry ?? this.entry,
      failure: resetFailure ? null : failure ?? this.failure,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      cancelFailure: cancelFailure ?? this.cancelFailure,
      statistics: statistics ?? this.statistics,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    disciplineCode,
    entry,
    failure,
    cancelStatus,
    cancelFailure,
    statistics,
  ];
}
