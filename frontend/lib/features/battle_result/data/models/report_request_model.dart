import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/battle_result/data/models/report_reason_model.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_params_entity.dart';

part 'report_request_model.g.dart';

/// Body of POST /battles/{id}/rounds/{roundId}/report.
@JsonSerializable(createFactory: false, includeIfNull: false)
final class ReportRequestModel {
  const ReportRequestModel({required this.reason, this.comment});

  Map<String, dynamic> toJson() => _$ReportRequestModelToJson(this);

  final ReportReasonModel reason;
  final String? comment;

  factory ReportRequestModel.fromEntity(ReportParamsEntity params) {
    final String? comment = params.comment?.trim();
    return ReportRequestModel(
      reason: ReportReasonModel.fromEntity(params.reason),
      comment: comment == null || comment.isEmpty ? null : comment,
    );
  }
}
