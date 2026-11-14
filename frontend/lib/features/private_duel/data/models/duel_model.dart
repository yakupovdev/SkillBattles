import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/battle_format_model.dart';
import 'package:skill_battles/core/data/models/public_player_model.dart';
import 'package:skill_battles/features/private_duel/data/models/duel_status_model.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_entity.dart';

part 'duel_model.g.dart';

/// Private code room.
@JsonSerializable(checked: true, createToJson: false)
final class DuelModel {
  const DuelModel({
    required this.id,
    required this.code,
    required this.disciplineCode,
    required this.format,
    required this.status,
    required this.host,
    required this.guest,
    required this.expiresAt,
    required this.battleId,
    required this.version,
  });

  factory DuelModel.fromJson(Map<String, dynamic> json) =>
      _$DuelModelFromJson(json);

  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final String code;

  @JsonKey(required: true)
  final String disciplineCode;

  @JsonKey(required: true)
  final BattleFormatModel format;

  @JsonKey(required: true)
  final DuelStatusModel status;

  @JsonKey(required: true)
  final PublicPlayerModel host;

  @JsonKey(required: true)
  final PublicPlayerModel? guest;

  @JsonKey(required: true)
  final DateTime expiresAt;

  @JsonKey(required: true)
  final String? battleId;

  @JsonKey(required: true)
  final int version;

  DuelEntity toEntity() => DuelEntity(
    id: id,
    code: code,
    disciplineCode: disciplineCode,
    status: status.toEntity(),
    host: host.toEntity(),
    guest: guest?.toEntity(),
    expiresAt: expiresAt,
    battleId: battleId,
    version: version,
  );
}
