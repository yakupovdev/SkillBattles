import 'package:equatable/equatable.dart';

/// One settled ranked result of the Pro rating graph (no artificial points
/// for season resets).
final class RatingHistoryPointEntity extends Equatable {
  const RatingHistoryPointEntity({
    required this.battleId,
    required this.seasonId,
    required this.finishedAt,
    required this.ratingBefore,
    required this.ratingAfter,
    required this.ratingDelta,
  });

  final String battleId;
  final String seasonId;
  final DateTime finishedAt;
  final int ratingBefore;
  final int ratingAfter;
  final int ratingDelta;

  @override
  List<Object?> get props => <Object?>[
    battleId,
    seasonId,
    finishedAt,
    ratingBefore,
    ratingAfter,
    ratingDelta,
  ];
}
