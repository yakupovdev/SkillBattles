import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/page_info_entity.dart';

part 'pagination_model.g.dart';

/// Page metadata.
@JsonSerializable(checked: true, createToJson: false)
final class PaginationModel {
  const PaginationModel({
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationModelFromJson(json);

  @JsonKey(required: true)
  final int page;

  @JsonKey(required: true)
  final int size;

  @JsonKey(required: true)
  final int totalElements;

  @JsonKey(required: true)
  final int totalPages;

  PageInfoEntity toEntity() => PageInfoEntity(
    page: page,
    size: size,
    totalElements: totalElements,
    totalPages: totalPages,
  );
}
