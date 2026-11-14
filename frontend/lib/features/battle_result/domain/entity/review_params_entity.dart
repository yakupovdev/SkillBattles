import 'package:equatable/equatable.dart';

/// [mistakesOnly] is a Pro filter: wrong and unanswered rounds only.
final class ReviewParamsEntity extends Equatable {
  const ReviewParamsEntity({required this.battleId, this.mistakesOnly = false});

  final String battleId;
  final bool mistakesOnly;

  @override
  List<Object?> get props => <Object?>[battleId, mistakesOnly];
}
