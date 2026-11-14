import 'package:equatable/equatable.dart';

/// Authoritative current access rights, computed by the server from the
/// verified subscription (never from the JWT or a client flag).
final class EntitlementsEntity extends Equatable {
  const EntitlementsEntity({
    required this.isPro,
    required this.version,
    required this.unlimitedRanked,
    required this.historyMatchLimit,
    required this.canViewCorrectAnswers,
    required this.canViewExplanations,
    required this.canViewAdvancedAnalytics,
    required this.canFilterMistakes,
  });

  final bool isPro;

  /// Monotonic account access version: a change invalidates every view of
  /// paid data even when the battle version is unchanged.
  final int version;
  final bool unlimitedRanked;

  /// 10 for Free, `null` for Pro.
  final int? historyMatchLimit;
  final bool canViewCorrectAnswers;
  final bool canViewExplanations;
  final bool canViewAdvancedAnalytics;
  final bool canFilterMistakes;

  @override
  List<Object?> get props => <Object?>[
    isPro,
    version,
    unlimitedRanked,
    historyMatchLimit,
    canViewCorrectAnswers,
    canViewExplanations,
    canViewAdvancedAnalytics,
    canFilterMistakes,
  ];
}
