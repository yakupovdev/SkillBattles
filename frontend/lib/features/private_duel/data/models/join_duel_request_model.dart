import 'package:json_annotation/json_annotation.dart';

part 'join_duel_request_model.g.dart';

/// Body of POST /duels/join.
@JsonSerializable(createFactory: false)
final class JoinDuelRequestModel {
  const JoinDuelRequestModel({required this.code});

  Map<String, dynamic> toJson() => _$JoinDuelRequestModelToJson(this);

  final String code;
}
