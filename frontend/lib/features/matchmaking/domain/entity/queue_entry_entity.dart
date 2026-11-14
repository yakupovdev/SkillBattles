import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_status.dart';

/// The account's ranked search.
final class QueueEntryEntity extends Equatable {
  const QueueEntryEntity({
    required this.id,
    required this.disciplineCode,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.ratingWindow,
    required this.battleId,
    required this.version,
    required this.error,
  });

  final String id;
  final String disciplineCode;
  final QueueStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  /// ± Elo around the own rating; widens with waiting time.
  final int ratingWindow;
  final String? battleId;
  final int version;

  /// Cause of an asynchronous cancellation (e.g. `QUOTA_EXHAUSTED`).
  final ApiFailure? error;

  bool get isTerminal =>
      status == QueueStatus.cancelled || status == QueueStatus.expired;

  @override
  List<Object?> get props => <Object?>[
    id,
    disciplineCode,
    status,
    createdAt,
    expiresAt,
    ratingWindow,
    battleId,
    version,
    error,
  ];
}
