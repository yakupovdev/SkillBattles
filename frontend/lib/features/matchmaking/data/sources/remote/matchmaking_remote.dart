import 'package:skill_battles/core/data/models/discipline_request_model.dart';
import 'package:skill_battles/core/utils/network/api_client.dart';
import 'package:skill_battles/core/utils/network/app_api.dart';
import 'package:skill_battles/core/utils/network/json_object.dart';
import 'package:skill_battles/features/matchmaking/data/models/queue_entry_model.dart';

abstract interface class MatchmakingRemote {
  Future<QueueEntryModel> joinQueue(DisciplineRequestModel request);

  Future<QueueEntryModel> getEntry(String id);

  Future<void> cancelEntry(String id);
}

final class MatchmakingRemoteImpl implements MatchmakingRemote {
  const MatchmakingRemoteImpl(this._client);

  final ApiClient _client;

  @override
  Future<QueueEntryModel> joinQueue(DisciplineRequestModel request) async {
    final Object? json = await _client.post(
      AppApi.matchmakingEntries,
      data: request.toJson(),
    );
    return QueueEntryModel.fromJson(asJsonObject(json));
  }

  @override
  Future<QueueEntryModel> getEntry(String id) async {
    final Object? json = await _client.get(AppApi.matchmakingEntry(id));
    return QueueEntryModel.fromJson(asJsonObject(json));
  }

  @override
  Future<void> cancelEntry(String id) async {
    await _client.delete(AppApi.matchmakingEntry(id));
  }
}
