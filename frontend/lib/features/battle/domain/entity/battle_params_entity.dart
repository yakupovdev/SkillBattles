import 'package:equatable/equatable.dart';

final class BattleParamsEntity extends Equatable {
  const BattleParamsEntity({required this.battleId});

  final String battleId;

  @override
  List<Object?> get props => <Object?>[battleId];
}
