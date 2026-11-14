import 'package:equatable/equatable.dart';

import 'package:skill_battles/features/battle_result/domain/entity/rematch_status.dart';

/// Consent of both participants of a terminal private battle. 60 s from the
/// first consent, never extended; one session per source battle.
final class RematchEntity extends Equatable {
  const RematchEntity({
    required this.sourceBattleId,
    required this.status,
    required this.requestedBy,
    required this.expiresAt,
    required this.battleId,
    required this.version,
  });

  final String sourceBattleId;
  final RematchStatus status;

  /// Ids of the participants who agreed.
  final List<String> requestedBy;
  final DateTime expiresAt;

  /// The new PRIVATE battle when [status] is matched.
  final String? battleId;
  final int version;

  bool hasConsentOf(String userId) => requestedBy.contains(userId);

  @override
  List<Object?> get props => <Object?>[
    sourceBattleId,
    status,
    requestedBy,
    expiresAt,
    battleId,
    version,
  ];
}
