import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_params_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/incoming_sticker_entity.dart';
import 'package:skill_battles/features/battle/domain/repository/battle_repository.dart';

final class WatchStickersUsecase
    implements Usecase<Stream<IncomingStickerEntity>, BattleParamsEntity> {
  const WatchStickersUsecase(this._repository);

  final BattleRepository _repository;

  @override
  Stream<IncomingStickerEntity> call(BattleParamsEntity params) =>
      _repository.watchStickers(params.battleId);
}
