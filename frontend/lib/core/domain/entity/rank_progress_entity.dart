import 'package:equatable/equatable.dart';

/// Rank and RP progress inside the current tier, computed by the server.
final class RankProgressEntity extends Equatable {
  const RankProgressEntity({
    required this.rankCode,
    required this.rankName,
    required this.leagueCode,
    required this.divisionRpCurrent,
    required this.divisionRpTarget,
    required this.floorRating,
    required this.ceilingExclusive,
  });

  final String rankCode;
  final String rankName;
  final String leagueCode;

  /// Rating above the tier floor.
  final int divisionRpCurrent;

  /// Width of the tier; `null` for the open top tier.
  final int? divisionRpTarget;
  final int floorRating;
  final int? ceilingExclusive;

  /// 0..1 inside the tier; `null` for the open top tier.
  double? get fraction {
    final int? target = divisionRpTarget;
    if (target == null || target <= 0) return null;
    return (divisionRpCurrent / target).clamp(0, 1).toDouble();
  }

  @override
  List<Object?> get props => <Object?>[
    rankCode,
    rankName,
    leagueCode,
    divisionRpCurrent,
    divisionRpTarget,
    floorRating,
    ceilingExclusive,
  ];
}
