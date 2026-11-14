import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/repository/connection_repository.dart';
import 'package:skill_battles/core/utils/realtime/realtime_client.dart';

final class ConnectionRepositoryImpl implements ConnectionRepository {
  const ConnectionRepositoryImpl({required this._realtime});

  final RealtimeClient _realtime;

  @override
  RealtimeStatus get status => _realtime.status;

  @override
  Stream<RealtimeStatus> watchStatus() => _realtime.statusChanges;
}
