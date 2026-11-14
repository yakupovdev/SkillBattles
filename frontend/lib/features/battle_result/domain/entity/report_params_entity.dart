import 'package:equatable/equatable.dart';

import 'package:skill_battles/features/battle_result/domain/entity/report_reason.dart';

/// Report of one shown round; [comment] is required for [ReportReason.other].
final class ReportParamsEntity extends Equatable {
  const ReportParamsEntity({
    required this.battleId,
    required this.roundId,
    required this.reason,
    this.comment,
  });

  final String battleId;
  final String roundId;
  final ReportReason reason;
  final String? comment;

  static const int maxCommentLength = 1000;

  @override
  List<Object?> get props => <Object?>[battleId, roundId, reason, comment];
}
