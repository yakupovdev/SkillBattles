import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/repository/connection_repository.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';

/// Emits the current status first, then every change.
final class WatchConnectionUsecase
    implements Usecase<Stream<RealtimeStatus>, NoParams> {
  const WatchConnectionUsecase(this._repository);

  final ConnectionRepository _repository;

  @override
  Stream<RealtimeStatus> call(NoParams params) async* {
    yield _repository.status;
    yield* _repository.watchStatus();
  }
}
