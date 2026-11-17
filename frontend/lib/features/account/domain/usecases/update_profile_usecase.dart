import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/update_profile_params_entity.dart';
import 'package:skill_battles/features/account/domain/entity/update_profile_result_entity.dart';
import 'package:skill_battles/features/account/domain/repository/account_repository.dart';

/// Rejects an empty update and a half password pair before the request.
final class UpdateProfileUsecase
    implements Usecase<Future<Either<Failure, UpdateProfileResultEntity>>, UpdateProfileParamsEntity> {
  const UpdateProfileUsecase(this._repository);

  final AccountRepository _repository;

  @override
  Future<Either<Failure, UpdateProfileResultEntity>> call(
    UpdateProfileParamsEntity params,
  ) async {
    if (params.isEmpty) {
      return const Left(ValidationFailure(message: 'Nothing to update.'));
    }
    if ((params.currentPassword == null) != (params.newPassword == null)) {
      return const Left(
        ValidationFailure(
          message: 'Enter your current password and a new password.',
        ),
      );
    }
    return _repository.updateProfile(params);
  }
}
