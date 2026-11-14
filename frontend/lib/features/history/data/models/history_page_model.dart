import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/pagination_model.dart';
import 'package:skill_battles/features/history/data/models/history_item_model.dart';
import 'package:skill_battles/features/history/domain/entity/history_page_entity.dart';

part 'history_page_model.g.dart';

/// Page of match history.
@JsonSerializable(checked: true, createToJson: false)
final class HistoryPageModel {
  const HistoryPageModel({
    required this.data,
    required this.pagination,
    required this.historyLimit,
  });

  factory HistoryPageModel.fromJson(Map<String, dynamic> json) =>
      _$HistoryPageModelFromJson(json);

  @JsonKey(required: true)
  final List<HistoryItemModel> data;

  @JsonKey(required: true)
  final PaginationModel pagination;

  @JsonKey(required: true)
  final int? historyLimit;

  HistoryPageEntity toEntity() => HistoryPageEntity(
    items: data
        .map((HistoryItemModel item) => item.toEntity())
        .toList(growable: false),
    page: pagination.toEntity(),
    historyLimit: historyLimit,
  );
}
