import 'package:equatable/equatable.dart';

/// One of the four answer options.
final class QuestionOptionEntity extends Equatable {
  const QuestionOptionEntity({required this.id, required this.text});

  final String id;
  final String text;

  @override
  List<Object?> get props => <Object?>[id, text];
}
