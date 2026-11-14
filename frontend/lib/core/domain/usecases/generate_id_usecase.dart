import 'package:uuid/uuid.dart';

import 'package:skill_battles/core/domain/usecases/usecase.dart';

/// A random UUID v4 for client idempotency keys (answer `submissionId`,
/// checkout `requestId`). The caller keeps it for retries.
final class GenerateIdUsecase implements Usecase<String, NoParams> {
  const GenerateIdUsecase(this._uuid);

  final Uuid _uuid;

  @override
  String call(NoParams params) => _uuid.v4();
}
