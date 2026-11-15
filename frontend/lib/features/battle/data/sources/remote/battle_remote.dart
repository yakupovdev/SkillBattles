import 'package:skill_battles/core/utils/network/api_client.dart';
import 'package:skill_battles/core/utils/network/app_api.dart';
import 'package:skill_battles/core/utils/network/json_object.dart';
import 'package:skill_battles/features/battle/data/models/answer_receipt_model.dart';
import 'package:skill_battles/features/battle/data/models/answer_request_model.dart';
import 'package:skill_battles/features/battle/data/models/battle_snapshot_model.dart';
import 'package:skill_battles/features/battle/data/models/readiness_request_model.dart';
import 'package:skill_battles/features/battle/data/models/sticker_receipt_model.dart';
import 'package:skill_battles/features/battle/data/models/sticker_request_model.dart';

/// Live battle endpoints. Result, review, rematch and reports are in the
/// battle_result feature.
abstract interface class BattleRemote {
  Future<BattleSnapshotModel> getBattle(String id);

  Future<BattleSnapshotModel> setReady(String id);

  Future<AnswerReceiptModel> submitAnswer(
    String id,
    AnswerRequestModel request,
  );

  Future<BattleSnapshotModel> surrender(String id);

  /// REST, never a STOMP SEND: the socket only delivers events.
  Future<StickerReceiptModel> sendSticker(
    String id,
    StickerRequestModel request,
  );
}

final class BattleRemoteImpl implements BattleRemote {
  const BattleRemoteImpl(this._client);

  final ApiClient _client;

  @override
  Future<BattleSnapshotModel> getBattle(String id) async {
    final Object? json = await _client.get(AppApi.battle(id));
    return BattleSnapshotModel.fromJson(asJsonObject(json));
  }

  @override
  Future<BattleSnapshotModel> setReady(String id) async {
    final Object? json = await _client.post(
      AppApi.battleReadiness(id),
      data: const ReadinessRequestModel(ready: true).toJson(),
    );
    return BattleSnapshotModel.fromJson(asJsonObject(json));
  }

  @override
  Future<AnswerReceiptModel> submitAnswer(
    String id,
    AnswerRequestModel request,
  ) async {
    final Object? json = await _client.post(
      AppApi.battleAnswers(id),
      data: request.toJson(),
    );
    return AnswerReceiptModel.fromJson(asJsonObject(json));
  }

  @override
  Future<BattleSnapshotModel> surrender(String id) async {
    final Object? json = await _client.post(AppApi.battleSurrender(id));
    return BattleSnapshotModel.fromJson(asJsonObject(json));
  }

  @override
  Future<StickerReceiptModel> sendSticker(
    String id,
    StickerRequestModel request,
  ) async {
    final Object? json = await _client.post(
      AppApi.battleStickers(id),
      data: request.toJson(),
    );
    return StickerReceiptModel.fromJson(asJsonObject(json));
  }
}
