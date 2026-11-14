import 'package:equatable/equatable.dart';

final class ReportEntity extends Equatable {
  const ReportEntity({
    required this.id,
    required this.roundId,
    required this.createdAt,
  });

  final String id;
  final String roundId;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[id, roundId, createdAt];
}
