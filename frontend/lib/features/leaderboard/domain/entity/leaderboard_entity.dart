import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/season_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entry_entity.dart';

/// Current-season top 50 of a discipline plus the own row.
final class LeaderboardEntity extends Equatable {
  const LeaderboardEntity({
    required this.disciplineCode,
    required this.season,
    required this.generatedAt,
    required this.top,
    required this.me,
  });

  final String disciplineCode;
  final SeasonEntity season;
  final DateTime generatedAt;
  final List<LeaderboardEntryEntity> top;

  /// `null` while the own season rollover is pending.
  final LeaderboardEntryEntity? me;

  @override
  List<Object?> get props => <Object?>[
    disciplineCode,
    season,
    generatedAt,
    top,
    me,
  ];
}
