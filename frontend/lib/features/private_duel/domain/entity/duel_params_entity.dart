import 'package:equatable/equatable.dart';

final class DuelParamsEntity extends Equatable {
  const DuelParamsEntity({required this.duelId});

  final String duelId;

  @override
  List<Object?> get props => <Object?>[duelId];
}
