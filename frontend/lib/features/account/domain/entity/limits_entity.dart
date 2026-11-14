import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/entitlements_entity.dart';
import 'package:skill_battles/core/domain/entity/plan_code.dart';

/// Authoritative ET ranked usage. One Free limit for all disciplines
/// together; private duels are never limited.
final class LimitsEntity extends Equatable {
  const LimitsEntity({
    required this.planCode,
    required this.date,
    required this.freeRankedLimit,
    required this.rankedStartedToday,
    required this.freeRankedRemaining,
    required this.resetsAt,
    required this.canStartRanked,
    required this.entitlements,
  });

  final PlanCode planCode;

  /// ET date of the counter.
  final DateTime date;
  final int freeRankedLimit;
  final int rankedStartedToday;

  /// `null` for Pro.
  final int? freeRankedRemaining;

  /// Next ET midnight (DST-aware), as an instant.
  final DateTime resetsAt;
  final bool canStartRanked;
  final EntitlementsEntity entitlements;

  @override
  List<Object?> get props => <Object?>[
    planCode,
    date,
    freeRankedLimit,
    rankedStartedToday,
    freeRankedRemaining,
    resetsAt,
    canStartRanked,
    entitlements,
  ];
}
