import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_reason.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_status.dart';

/// A targeted invitation into an existing private room. [id] is the
/// invitation id (never the room [duelId], the `requestId` or the
/// [battleId]). No room code is delivered.
final class DuelInvitationEntity extends Equatable {
  const DuelInvitationEntity({
    required this.id,
    required this.duelId,
    required this.host,
    required this.recipient,
    required this.disciplineCode,
    required this.status,
    required this.reason,
    required this.createdAt,
    required this.expiresAt,
    required this.battleId,
    required this.version,
    required this.isIncoming,
  });

  final String id;
  final String duelId;
  final PublicPlayerEntity host;
  final PublicPlayerEntity recipient;
  final String disciplineCode;
  final DuelInvitationStatus status;
  final DuelInvitationReason? reason;
  final DateTime createdAt;

  /// min(createdAt + 60 s, room expiry), server clock; never renewed.
  final DateTime expiresAt;

  /// Only for ACCEPTED; `null` when someone else filled the room.
  final String? battleId;
  final int version;

  /// Whether the signed-in user is the [recipient] (resolved when read).
  final bool isIncoming;

  @override
  List<Object?> get props => <Object?>[
    id,
    duelId,
    host,
    recipient,
    disciplineCode,
    status,
    reason,
    createdAt,
    expiresAt,
    battleId,
    version,
    isIncoming,
  ];
}
