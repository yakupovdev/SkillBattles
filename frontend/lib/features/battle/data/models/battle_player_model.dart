import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/battle/domain/entity/battle_player_entity.dart';

part 'battle_player_model.g.dart';

/// Player state inside a battle.
@JsonSerializable(checked: true, createToJson: false)
final class BattlePlayerModel {
  const BattlePlayerModel({
    required this.id,
    required this.nickname,
    required this.isPro,
    required this.rating,
    required this.rankCode,
    required this.ready,
    required this.connected,
    required this.reconnectDeadline,
    required this.score,
    required this.correctCount,
    required this.streak,
    required this.answeredCurrentRound,
  });

  factory BattlePlayerModel.fromJson(Map<String, dynamic> json) =>
      _$BattlePlayerModelFromJson(json);

  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final String nickname;

  @JsonKey(required: true)
  final bool isPro;

  @JsonKey(required: true)
  final int rating;

  @JsonKey(required: true)
  final String rankCode;

  @JsonKey(required: true)
  final bool ready;

  @JsonKey(required: true)
  final bool connected;

  @JsonKey(required: true)
  final DateTime? reconnectDeadline;

  @JsonKey(required: true)
  final int score;

  @JsonKey(required: true)
  final int correctCount;

  @JsonKey(required: true)
  final int streak;

  @JsonKey(required: true)
  final bool answeredCurrentRound;

  BattlePlayerEntity toEntity() => BattlePlayerEntity(
    id: id,
    nickname: nickname,
    isPro: isPro,
    rating: rating,
    rankCode: rankCode,
    ready: ready,
    connected: connected,
    reconnectDeadline: reconnectDeadline,
    score: score,
    correctCount: correctCount,
    streak: streak,
    answeredCurrentRound: answeredCurrentRound,
  );
}
