import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/entitlements_entity.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/streaks_entity.dart';

final class StatisticsEntity extends Equatable {
  const StatisticsEntity({
    required this.entitlements,
    required this.streaks,
    required this.disciplines,
  });

  final EntitlementsEntity entitlements;
  final StreaksEntity streaks;
  final List<DisciplineStatsEntity> disciplines;

  DisciplineStatsEntity? forDiscipline(String code) {
    for (final DisciplineStatsEntity stats in disciplines) {
      if (stats.disciplineCode == code) return stats;
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[entitlements, streaks, disciplines];
}
