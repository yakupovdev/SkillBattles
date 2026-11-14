import 'package:equatable/equatable.dart';

final class QueueEntryParamsEntity extends Equatable {
  const QueueEntryParamsEntity({required this.entryId});

  final String entryId;

  @override
  List<Object?> get props => <Object?>[entryId];
}
