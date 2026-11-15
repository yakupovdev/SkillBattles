import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle/domain/entity/send_sticker_params_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/repository/battle_repository.dart';

/// Sends a sticker to the opponent. [StickerId.unknown] is rejected before
/// any request.
final class SendStickerUsecase
    implements
        Usecase<
          Future<Either<Failure, StickerReceiptEntity>>,
          SendStickerParamsEntity
        > {
  const SendStickerUsecase(this._repository);

  final BattleRepository _repository;

  @override
  Future<Either<Failure, StickerReceiptEntity>> call(
    SendStickerParamsEntity params,
  ) async {
    if (!params.stickerId.isKnown) {
      return const Left(ValidationFailure(message: 'Unsupported sticker.'));
    }
    return _repository.sendSticker(params);
  }
}
