import 'package:equatable/equatable.dart';

/// Account-wide ET daily and weekly streaks (no freezes). Separate from the
/// in-battle answer streak and the win streak.
final class StreaksEntity extends Equatable {
  const StreaksEntity({
    required this.dailyCurrent,
    required this.dailyBest,
    required this.lastQualifiedDate,
    required this.weeklyCurrent,
    required this.weeklyBest,
    required this.currentWeekStart,
    required this.currentWeekActiveDays,
    required this.currentWeekTarget,
  });

  final int dailyCurrent;
  final int dailyBest;
  final DateTime? lastQualifiedDate;
  final int weeklyCurrent;
  final int weeklyBest;
  final DateTime currentWeekStart;
  final int currentWeekActiveDays;
  final int currentWeekTarget;

  @override
  List<Object?> get props => <Object?>[
    dailyCurrent,
    dailyBest,
    lastQualifiedDate,
    weeklyCurrent,
    weeklyBest,
    currentWeekStart,
    currentWeekActiveDays,
    currentWeekTarget,
  ];
}
