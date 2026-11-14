import 'package:equatable/equatable.dart';

import 'package:skill_battles/features/catalog/domain/entity/rank_tier_entity.dart';

/// The server's rank table; the client never derives ranks on its own
/// thresholds.
final class RankLadderEntity extends Equatable {
  const RankLadderEntity({required this.tiers});

  /// Ordered from the lowest floor.
  final List<RankTierEntity> tiers;

  RankTierEntity? byCode(String code) {
    for (final RankTierEntity tier in tiers) {
      if (tier.code == code) return tier;
    }
    return null;
  }

  /// The tier after [code], `null` at the top or for an unknown code.
  RankTierEntity? next(String code) {
    for (int i = 0; i < tiers.length - 1; i++) {
      if (tiers[i].code == code) return tiers[i + 1];
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[tiers];
}
