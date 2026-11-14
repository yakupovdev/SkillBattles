part of 'battle_result_bloc.dart';

final class BattleResultState extends Equatable {
  const BattleResultState({
    this.resultStatus = LoadStatus.initial,
    this.result,
    this.resultFailure,
    this.reviewStatus = LoadStatus.initial,
    this.review,
    this.reviewFailure,
    this.mistakesOnly = false,
    this.rematch,
    this.rematchActionStatus = LoadStatus.initial,
    this.rematchFailure,
    this.reportStatus = LoadStatus.initial,
    this.reportingRoundId,
    this.reportFailure,
    this.reportedRoundIds = const <String>{},
  });

  final LoadStatus resultStatus;
  final BattleResultEntity? result;
  final Failure? resultFailure;
  final LoadStatus reviewStatus;
  final BattleReviewEntity? review;
  final Failure? reviewFailure;
  final bool mistakesOnly;
  final RematchEntity? rematch;
  final LoadStatus rematchActionStatus;
  final Failure? rematchFailure;
  final LoadStatus reportStatus;
  final String? reportingRoundId;
  final Failure? reportFailure;
  final Set<String> reportedRoundIds;

  /// The new private battle once both agreed.
  String? get rematchBattleId =>
      rematch?.status == RematchStatus.matched ? rematch?.battleId : null;

  BattleResultState copyWith({
    LoadStatus? resultStatus,
    BattleResultEntity? result,
    Failure? resultFailure,
    LoadStatus? reviewStatus,
    BattleReviewEntity? review,
    Failure? reviewFailure,
    bool? mistakesOnly,
    RematchEntity? rematch,
    LoadStatus? rematchActionStatus,
    Failure? rematchFailure,
    LoadStatus? reportStatus,
    String? reportingRoundId,
    Failure? reportFailure,
    Set<String>? reportedRoundIds,
    bool resetResultFailure = false,
    bool resetReview = false,
    bool resetReviewFailure = false,
    bool resetRematchFailure = false,
    bool resetReportFailure = false,
  }) {
    return BattleResultState(
      resultStatus: resultStatus ?? this.resultStatus,
      result: result ?? this.result,
      resultFailure: resetResultFailure
          ? null
          : resultFailure ?? this.resultFailure,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      review: resetReview ? null : review ?? this.review,
      reviewFailure: resetReviewFailure || resetReview
          ? null
          : reviewFailure ?? this.reviewFailure,
      mistakesOnly: mistakesOnly ?? this.mistakesOnly,
      rematch: rematch ?? this.rematch,
      rematchActionStatus: rematchActionStatus ?? this.rematchActionStatus,
      rematchFailure: resetRematchFailure
          ? null
          : rematchFailure ?? this.rematchFailure,
      reportStatus: reportStatus ?? this.reportStatus,
      reportingRoundId: reportingRoundId ?? this.reportingRoundId,
      reportFailure: resetReportFailure
          ? null
          : reportFailure ?? this.reportFailure,
      reportedRoundIds: reportedRoundIds ?? this.reportedRoundIds,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    resultStatus,
    result,
    resultFailure,
    reviewStatus,
    review,
    reviewFailure,
    mistakesOnly,
    rematch,
    rematchActionStatus,
    rematchFailure,
    reportStatus,
    reportingRoundId,
    reportFailure,
    reportedRoundIds,
  ];
}
