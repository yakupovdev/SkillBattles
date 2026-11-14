import 'package:equatable/equatable.dart';

/// An ET season; [endsAt] is exclusive.
final class SeasonEntity extends Equatable {
  const SeasonEntity({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;

  @override
  List<Object?> get props => <Object?>[id, name, startsAt, endsAt];
}
