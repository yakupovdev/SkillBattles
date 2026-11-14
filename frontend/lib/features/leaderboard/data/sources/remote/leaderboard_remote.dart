import 'package:skill_battles/core/utils/network/api_client.dart';
import 'package:skill_battles/core/utils/network/app_api.dart';
import 'package:skill_battles/core/utils/network/json_object.dart';
import 'package:skill_battles/features/leaderboard/data/models/leaderboard_model.dart';

abstract interface class LeaderboardRemote {
  Future<LeaderboardModel> getLeaderboard(String disciplineCode);
}

final class LeaderboardRemoteImpl implements LeaderboardRemote {
  const LeaderboardRemoteImpl(this._client);

  final ApiClient _client;

  @override
  Future<LeaderboardModel> getLeaderboard(String disciplineCode) async {
    final Object? json = await _client.get(AppApi.leaderboard(disciplineCode));
    return LeaderboardModel.fromJson(asJsonObject(json));
  }
}
