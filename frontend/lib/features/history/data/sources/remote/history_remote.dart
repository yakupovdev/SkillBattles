import 'package:skill_battles/core/data/models/competition_mode_model.dart';
import 'package:skill_battles/core/utils/network/api_client.dart';
import 'package:skill_battles/core/utils/network/app_api.dart';
import 'package:skill_battles/core/utils/network/json_object.dart';
import 'package:skill_battles/features/history/data/models/history_page_model.dart';

abstract interface class HistoryRemote {
  /// [sort] is `createdAt,asc` or `createdAt,desc` (the server default).
  Future<HistoryPageModel> getBattles({
    int? page,
    int? size,
    String? sort,
    String? disciplineCode,
    CompetitionModeModel? mode,
  });
}

final class HistoryRemoteImpl implements HistoryRemote {
  const HistoryRemoteImpl(this._client);

  final ApiClient _client;

  @override
  Future<HistoryPageModel> getBattles({
    int? page,
    int? size,
    String? sort,
    String? disciplineCode,
    CompetitionModeModel? mode,
  }) async {
    final Object? json = await _client.get(
      AppApi.meBattles,
      queryParameters: <String, dynamic>{
        AppApi.pageKey: ?page,
        AppApi.sizeKey: ?size,
        AppApi.sortKey: ?sort,
        AppApi.disciplineCodeKey: ?disciplineCode,
        AppApi.modeKey: ?mode?.name.toUpperCase(),
      },
    );
    return HistoryPageModel.fromJson(asJsonObject(json));
  }
}
