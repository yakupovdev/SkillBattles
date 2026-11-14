import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/pagination_model.dart';
import 'package:skill_battles/features/account/data/models/season_peak_model.dart';
import 'package:skill_battles/features/account/domain/entity/season_history_page_entity.dart';

part 'season_history_page_model.g.dart';

/// Page of completed-season results.
@JsonSerializable(checked: true, createToJson: false)
final class SeasonHistoryPageModel {
  const SeasonHistoryPageModel({required this.data, required this.pagination});

  factory SeasonHistoryPageModel.fromJson(Map<String, dynamic> json) =>
      _$SeasonHistoryPageModelFromJson(json);

  @JsonKey(required: true)
  final List<SeasonPeakModel> data;

  @JsonKey(required: true)
  final PaginationModel pagination;

  SeasonHistoryPageEntity toEntity() => SeasonHistoryPageEntity(
    items: data
        .map((SeasonPeakModel peak) => peak.toEntity())
        .toList(growable: false),
    page: pagination.toEntity(),
  );
}
