import 'package:skill_battles/core/data/models/season_model.dart';
import 'package:skill_battles/core/utils/network/api_client.dart';
import 'package:skill_battles/core/utils/network/app_api.dart';
import 'package:skill_battles/core/utils/network/json_object.dart';
import 'package:skill_battles/features/catalog/data/models/battle_mode_model.dart';
import 'package:skill_battles/features/catalog/data/models/rank_tier_model.dart';

abstract interface class CatalogRemote {
  Future<List<BattleModeModel>> getBattleModes();

  Future<List<RankTierModel>> getRanks();

  Future<SeasonModel> getCurrentSeason();
}

final class CatalogRemoteImpl implements CatalogRemote {
  const CatalogRemoteImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<BattleModeModel>> getBattleModes() async {
    final Object? json = await _client.get(AppApi.battleModes);
    return asJsonObjectList(json)
        .map(BattleModeModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<RankTierModel>> getRanks() async {
    final Object? json = await _client.get(AppApi.ranks);
    return asJsonObjectList(json)
        .map(RankTierModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<SeasonModel> getCurrentSeason() async {
    final Object? json = await _client.get(AppApi.currentSeason);
    return SeasonModel.fromJson(asJsonObject(json));
  }
}
