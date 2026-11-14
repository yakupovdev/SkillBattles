/// Technical error thrown by data sources; repositories convert it to a
/// `Failure`.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// A response has a shape the data layer cannot read.
final class ParsingException extends AppException {
  const ParsingException(super.message);
}

/// The secure token storage could not be read or written.
final class StorageException extends AppException {
  const StorageException(super.message);
}
