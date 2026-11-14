import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/battle_result/domain/entity/report_reason.dart';

/// Reason of a question report.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum ReportReasonModel {
  incorrectAnswer,
  unclearQuestion,
  typo,
  other;

  static ReportReasonModel fromEntity(ReportReason reason) => switch (reason) {
    ReportReason.incorrectAnswer => ReportReasonModel.incorrectAnswer,
    ReportReason.unclearQuestion => ReportReasonModel.unclearQuestion,
    ReportReason.typo => ReportReasonModel.typo,
    ReportReason.other => ReportReasonModel.other,
  };
}
