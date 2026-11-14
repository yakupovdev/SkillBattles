part of 'private_duel_bloc.dart';

final class PrivateDuelState extends Equatable {
  const PrivateDuelState({
    this.loadStatus = LoadStatus.initial,
    this.duel,
    this.failure,
    this.cancelStatus = LoadStatus.initial,
    this.cancelFailure,
  });

  final LoadStatus loadStatus;
  final DuelEntity? duel;
  final Failure? failure;
  final LoadStatus cancelStatus;
  final Failure? cancelFailure;

  String? get battleId =>
      duel?.status == DuelStatus.matched ? duel?.battleId : null;

  PrivateDuelState copyWith({
    LoadStatus? loadStatus,
    DuelEntity? duel,
    Failure? failure,
    LoadStatus? cancelStatus,
    Failure? cancelFailure,
    bool resetFailure = false,
  }) {
    return PrivateDuelState(
      loadStatus: loadStatus ?? this.loadStatus,
      duel: duel ?? this.duel,
      failure: resetFailure ? null : failure ?? this.failure,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      cancelFailure: cancelFailure ?? this.cancelFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    duel,
    failure,
    cancelStatus,
    cancelFailure,
  ];
}
