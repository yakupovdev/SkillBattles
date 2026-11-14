import 'package:skill_battles/core/data/models/discipline_request_model.dart';
import 'package:skill_battles/core/utils/network/api_client.dart';
import 'package:skill_battles/core/utils/network/app_api.dart';
import 'package:skill_battles/core/utils/network/json_object.dart';
import 'package:skill_battles/features/private_duel/data/models/duel_model.dart';
import 'package:skill_battles/features/private_duel/data/models/join_duel_request_model.dart';

abstract interface class PrivateDuelRemote {
  Future<DuelModel> createDuel(DisciplineRequestModel request);

  Future<DuelModel> joinDuel(JoinDuelRequestModel request);

  Future<DuelModel> getDuel(String id);

  Future<void> cancelDuel(String id);
}

final class PrivateDuelRemoteImpl implements PrivateDuelRemote {
  const PrivateDuelRemoteImpl(this._client);

  final ApiClient _client;

  @override
  Future<DuelModel> createDuel(DisciplineRequestModel request) async {
    final Object? json = await _client.post(
      AppApi.duels,
      data: request.toJson(),
    );
    return DuelModel.fromJson(asJsonObject(json));
  }

  @override
  Future<DuelModel> joinDuel(JoinDuelRequestModel request) async {
    final Object? json = await _client.post(
      AppApi.duelsJoin,
      data: request.toJson(),
    );
    return DuelModel.fromJson(asJsonObject(json));
  }

  @override
  Future<DuelModel> getDuel(String id) async {
    final Object? json = await _client.get(AppApi.duel(id));
    return DuelModel.fromJson(asJsonObject(json));
  }

  @override
  Future<void> cancelDuel(String id) async {
    await _client.delete(AppApi.duel(id));
  }
}
