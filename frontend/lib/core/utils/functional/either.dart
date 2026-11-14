/// Result of an operation: either a [Left] failure or a [Right] success.
sealed class Either<L, R> {
  const Either();

  bool isLeft() => this is Left<L, R>;

  bool isRight() => this is Right<L, R>;

  /// Folds both branches into one value.
  T match<T>(T Function(L left) onLeft, T Function(R right) onRight) =>
      switch (this) {
        Left<L, R>(:final L value) => onLeft(value),
        Right<L, R>(:final R value) => onRight(value),
      };

  /// Transforms the success value, keeping a failure as is.
  Either<L, T> map<T>(T Function(R right) f) => switch (this) {
    Left<L, R>(:final L value) => Left<L, T>(value),
    Right<L, R>(:final R value) => Right<L, T>(f(value)),
  };

  /// Transforms the failure value, keeping a success as is.
  Either<T, R> mapLeft<T>(T Function(L left) f) => switch (this) {
    Left<L, R>(:final L value) => Left<T, R>(f(value)),
    Right<L, R>(:final R value) => Right<T, R>(value),
  };

  /// Chains an operation that runs only on success.
  Either<L, T> flatMap<T>(Either<L, T> Function(R right) f) => switch (this) {
    Left<L, R>(:final L value) => Left<L, T>(value),
    Right<L, R>(:final R value) => f(value),
  };

  /// The success value, or [orElse] computed from the failure.
  R getOrElse(R Function(L left) orElse) => switch (this) {
    Left<L, R>(:final L value) => orElse(value),
    Right<L, R>(:final R value) => value,
  };

  /// The failure value, `null` on success.
  L? getLeft() => switch (this) {
    Left<L, R>(:final L value) => value,
    Right<L, R>() => null,
  };

  /// The success value, `null` on failure.
  R? toNullable() => switch (this) {
    Left<L, R>() => null,
    Right<L, R>(:final R value) => value,
  };
}

final class Left<L, R> extends Either<L, R> {
  const Left(this.value);

  final L value;

  @override
  bool operator ==(Object other) => other is Left<L, R> && other.value == value;

  @override
  int get hashCode => Object.hash(Left, value);

  @override
  String toString() => 'Left($value)';
}

final class Right<L, R> extends Either<L, R> {
  const Right(this.value);

  final R value;

  @override
  bool operator ==(Object other) =>
      other is Right<L, R> && other.value == value;

  @override
  int get hashCode => Object.hash(Right, value);

  @override
  String toString() => 'Right($value)';
}

/// Success value of an operation that returns nothing.
final class Unit {
  const Unit._();

  @override
  String toString() => '()';
}

const Unit unit = Unit._();
