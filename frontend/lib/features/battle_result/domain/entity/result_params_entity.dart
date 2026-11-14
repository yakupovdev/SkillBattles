import 'package:equatable/equatable.dart';

final class ResultParamsEntity extends Equatable {
  const ResultParamsEntity({required this.battleId});

  final String battleId;

  @override
  List<Object?> get props => <Object?>[battleId];
}
