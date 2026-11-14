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
  });

  final RankedSearchStatus status;
  final String? disciplineCode;
  final QueueEntryEntity? entry;

  /// Why joining failed (429 with `resetsAt`, activity conflict, …).
  final Failure? failure;
  final LoadStatus cancelStatus;
  final Failure? cancelFailure;

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
    bool resetFailure = false,
  }) {
    return RankedSearchState(
      status: status ?? this.status,
      disciplineCode: disciplineCode ?? this.disciplineCode,
      entry: entry ?? this.entry,
      failure: resetFailure ? null : failure ?? this.failure,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      cancelFailure: cancelFailure ?? this.cancelFailure,
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
  ];
}
