import 'package:skill_battles/core/data/models/battle_result_model.dart';
import 'package:skill_battles/core/utils/network/api_client.dart';
import 'package:skill_battles/core/utils/network/app_api.dart';
import 'package:skill_battles/core/utils/network/json_object.dart';
import 'package:skill_battles/features/battle_result/data/models/battle_review_model.dart';
import 'package:skill_battles/features/battle_result/data/models/rematch_model.dart';
import 'package:skill_battles/features/battle_result/data/models/report_request_model.dart';
import 'package:skill_battles/features/battle_result/data/models/report_response_model.dart';

/// Endpoints of a terminal battle.
abstract interface class BattleResultRemote {
  Future<BattleResultModel> getResult(String id);

  Future<BattleReviewModel> getReview(String id, {bool? mistakesOnly});

  Future<RematchModel> requestRematch(String id);

  Future<RematchModel> getRematch(String id);

  Future<void> cancelRematch(String id);

  Future<ReportResponseModel> reportRound(
    String id,
    String roundId,
    ReportRequestModel request,
  );
}

final class BattleResultRemoteImpl implements BattleResultRemote {
  const BattleResultRemoteImpl(this._client);

  final ApiClient _client;

  @override
  Future<BattleResultModel> getResult(String id) async {
    final Object? json = await _client.get(AppApi.battleResult(id));
    return BattleResultModel.fromJson(asJsonObject(json));
  }

  @override
  Future<BattleReviewModel> getReview(String id, {bool? mistakesOnly}) async {
    final Object? json = await _client.get(
      AppApi.battleReview(id),
      queryParameters: <String, dynamic>{AppApi.mistakesOnlyKey: ?mistakesOnly},
    );
    return BattleReviewModel.fromJson(asJsonObject(json));
  }

  @override
  Future<RematchModel> requestRematch(String id) async {
    final Object? json = await _client.post(AppApi.battleRematch(id));
    return RematchModel.fromJson(asJsonObject(json));
  }

  @override
  Future<RematchModel> getRematch(String id) async {
    final Object? json = await _client.get(AppApi.battleRematch(id));
    return RematchModel.fromJson(asJsonObject(json));
  }

  @override
  Future<void> cancelRematch(String id) async {
    await _client.delete(AppApi.battleRematch(id));
  }

  @override
  Future<ReportResponseModel> reportRound(
    String id,
    String roundId,
    ReportRequestModel request,
  ) async {
    final Object? json = await _client.post(
      AppApi.roundReport(id, roundId),
      data: request.toJson(),
    );
    return ReportResponseModel.fromJson(asJsonObject(json));
  }
}
