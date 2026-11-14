import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/battle_format_model.dart';

part 'discipline_request_model.g.dart';

/// Discipline and format of a ranked search or a private room.
@JsonSerializable(createFactory: false)
final class DisciplineRequestModel {
  const DisciplineRequestModel({
    required this.disciplineCode,
    required this.format,
  });

  Map<String, dynamic> toJson() => _$DisciplineRequestModelToJson(this);

  final String disciplineCode;
  final BattleFormatModel format;
}
