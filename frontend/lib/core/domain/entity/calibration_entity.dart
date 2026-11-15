import 'package:equatable/equatable.dart';

/// Lifetime calibration of a discipline rating (K = 64 for the first five
/// settled ranked matches, 32 afterwards). Not reset by seasons.
final class CalibrationEntity extends Equatable {
  const CalibrationEntity({
    required this.completedMatches,
    required this.matchesRemaining,
    required this.isCalibrating,
    required this.nextKFactor,
  });

  final int completedMatches;
  final int matchesRemaining;
  final bool isCalibrating;
  final int nextKFactor;

  @override
  List<Object?> get props => <Object?>[
    completedMatches,
    matchesRemaining,
    isCalibrating,
    nextKFactor,
  ];
}
