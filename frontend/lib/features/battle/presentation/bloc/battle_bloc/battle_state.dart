part of 'battle_bloc.dart';

/// Lifecycle of the own answer in the current round.
enum SubmissionStatus {
  /// Sent, no receipt yet — not accepted.
  sending,

  /// The server accepted it; final.
  accepted,

  /// Not confirmed (e.g. network); retry with the same id and option.
  failed,

  /// The round closed before the answer was accepted.
  closed,
}

final class AnswerSubmission extends Equatable {
  const AnswerSubmission({
    required this.roundId,
    required this.optionId,
    required this.submissionId,
    required this.status,
    this.failure,
  });

  final String roundId;
  final String optionId;
  final String submissionId;
  final SubmissionStatus status;
  final Failure? failure;

  AnswerSubmission copyWith({
    SubmissionStatus? status,
    Failure? failure,
    bool resetFailure = false,
  }) {
    return AnswerSubmission(
      roundId: roundId,
      optionId: optionId,
      submissionId: submissionId,
      status: status ?? this.status,
      failure: resetFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    roundId,
    optionId,
    submissionId,
    status,
    failure,
  ];
}

final class BattleState extends Equatable {
  const BattleState({
    this.loadStatus = LoadStatus.initial,
    this.failure,
    this.snapshot,
    this.roundId,
    this.selectedOptionId,
    this.submission,
    this.readyStatus = LoadStatus.initial,
    this.readyFailure,
    this.surrenderStatus = LoadStatus.initial,
    this.surrenderFailure,
    this.connection = RealtimeStatus.connecting,
  });

  final LoadStatus loadStatus;
  final Failure? failure;
  final BattleSnapshotEntity? snapshot;

  /// Round the local selection belongs to.
  final String? roundId;
  final String? selectedOptionId;
  final AnswerSubmission? submission;
  final LoadStatus readyStatus;
  final Failure? readyFailure;
  final LoadStatus surrenderStatus;
  final Failure? surrenderFailure;
  final RealtimeStatus connection;

  BattlePhase? get phase => snapshot?.phase;

  /// Once an answer was sent, the choice is locked to it.
  bool get canChangeSelection =>
      phase == BattlePhase.question && submission == null;

  bool get canSubmit =>
      phase == BattlePhase.question &&
      selectedOptionId != null &&
      (submission == null || submission!.status == SubmissionStatus.failed);

  BattleState copyWith({
    LoadStatus? loadStatus,
    Failure? failure,
    String? selectedOptionId,
    AnswerSubmission? submission,
    LoadStatus? readyStatus,
    Failure? readyFailure,
    LoadStatus? surrenderStatus,
    Failure? surrenderFailure,
    RealtimeStatus? connection,
    bool resetFailure = false,
    bool resetReadyFailure = false,
  }) {
    return BattleState(
      loadStatus: loadStatus ?? this.loadStatus,
      failure: resetFailure ? null : failure ?? this.failure,
      snapshot: snapshot,
      roundId: roundId,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      submission: submission ?? this.submission,
      readyStatus: readyStatus ?? this.readyStatus,
      readyFailure: resetReadyFailure
          ? null
          : readyFailure ?? this.readyFailure,
      surrenderStatus: surrenderStatus ?? this.surrenderStatus,
      surrenderFailure: surrenderFailure ?? this.surrenderFailure,
      connection: connection ?? this.connection,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    failure,
    snapshot,
    roundId,
    selectedOptionId,
    submission,
    readyStatus,
    readyFailure,
    surrenderStatus,
    surrenderFailure,
    connection,
  ];
}
