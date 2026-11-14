import 'package:equatable/equatable.dart';

/// One application operation. [Result] is the full return type, including
/// `Future` and `Either`.
abstract interface class Usecase<Result, Params> {
  Result call(Params params);
}

/// Input of an operation without parameters.
final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => <Object?>[];
}
