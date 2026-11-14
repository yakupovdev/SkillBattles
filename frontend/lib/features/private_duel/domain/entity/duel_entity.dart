import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_status.dart';

/// A private, unranked code room (6 characters, 10 minutes, one guest).
final class DuelEntity extends Equatable {
  const DuelEntity({
    required this.id,
    required this.code,
    required this.disciplineCode,
    required this.status,
    required this.host,
    required this.guest,
    required this.expiresAt,
    required this.battleId,
    required this.version,
  });

  final String id;
  final String code;
  final String disciplineCode;
  final DuelStatus status;
  final PublicPlayerEntity host;
  final PublicPlayerEntity? guest;
  final DateTime expiresAt;
  final String? battleId;
  final int version;

  @override
  List<Object?> get props => <Object?>[
    id,
    code,
    disciplineCode,
    status,
    host,
    guest,
    expiresAt,
    battleId,
    version,
  ];
}
