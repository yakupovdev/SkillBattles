import 'package:skill_battles/core/data/models/user_model.dart';
import 'package:skill_battles/core/utils/network/api_client.dart';
import 'package:skill_battles/core/utils/network/app_api.dart';
import 'package:skill_battles/core/utils/network/json_object.dart';
import 'package:skill_battles/features/account/data/models/activity_response_model.dart';
import 'package:skill_battles/features/account/data/models/limits_response_model.dart';
import 'package:skill_battles/features/account/data/models/season_history_page_model.dart';
import 'package:skill_battles/features/account/data/models/statistics_response_model.dart';
import 'package:skill_battles/features/account/data/models/update_profile_request_model.dart';
import 'package:skill_battles/features/account/data/models/update_profile_response_model.dart';

abstract interface class AccountRemote {
  Future<UserModel> getMe();

  Future<UpdateProfileResponseModel> updateMe(
    UpdateProfileRequestModel request,
  );

  Future<StatisticsResponseModel> getStatistics();

  Future<LimitsResponseModel> getLimits();

  Future<ActivityResponseModel> getActivity();

  Future<SeasonHistoryPageModel> getSeasons({
    int? page,
    int? size,
    String? disciplineCode,
  });
}

final class AccountRemoteImpl implements AccountRemote {
  const AccountRemoteImpl(this._client);

  final ApiClient _client;

  @override
  Future<UserModel> getMe() async {
    final Object? json = await _client.get(AppApi.me);
    return UserModel.fromJson(asJsonObject(json));
  }

  @override
  Future<UpdateProfileResponseModel> updateMe(
    UpdateProfileRequestModel request,
  ) async {
    final Object? json = await _client.patch(AppApi.me, data: request.toJson());
    return UpdateProfileResponseModel.fromJson(asJsonObject(json));
  }

  @override
  Future<StatisticsResponseModel> getStatistics() async {
    final Object? json = await _client.get(AppApi.meStatistics);
    return StatisticsResponseModel.fromJson(asJsonObject(json));
  }

  @override
  Future<LimitsResponseModel> getLimits() async {
    final Object? json = await _client.get(AppApi.meLimits);
    return LimitsResponseModel.fromJson(asJsonObject(json));
  }

  @override
  Future<ActivityResponseModel> getActivity() async {
    final Object? json = await _client.get(AppApi.meActivity);
    return ActivityResponseModel.fromJson(asJsonObject(json));
  }

  @override
  Future<SeasonHistoryPageModel> getSeasons({
    int? page,
    int? size,
    String? disciplineCode,
  }) async {
    final Object? json = await _client.get(
      AppApi.meSeasons,
      queryParameters: <String, dynamic>{
        AppApi.pageKey: ?page,
        AppApi.sizeKey: ?size,
        AppApi.disciplineCodeKey: ?disciplineCode,
      },
    );
    return SeasonHistoryPageModel.fromJson(asJsonObject(json));
  }
}
