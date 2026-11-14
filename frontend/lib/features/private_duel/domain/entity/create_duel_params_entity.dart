import 'package:equatable/equatable.dart';

final class CreateDuelParamsEntity extends Equatable {
  const CreateDuelParamsEntity({required this.disciplineCode});

  final String disciplineCode;

  @override
  List<Object?> get props => <Object?>[disciplineCode];
}
