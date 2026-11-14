import 'package:equatable/equatable.dart';

/// One of the ordered rank thresholds served by `GET /ranks`.
final class RankTierEntity extends Equatable {
  const RankTierEntity({
    required this.code,
    required this.displayName,
    required this.leagueCode,
    required this.floorRating,
    required this.ceilingExclusive,
    required this.divisionNumber,
  });

  final String code;
  final String displayName;
  final String leagueCode;
  final int floorRating;

  /// `null` for the top tier.
  final int? ceilingExclusive;

  /// 1/2/3; `null` for the single-division leagues.
  final int? divisionNumber;

  @override
  List<Object?> get props => <Object?>[
    code,
    displayName,
    leagueCode,
    floorRating,
    ceilingExclusive,
    divisionNumber,
  ];
}
