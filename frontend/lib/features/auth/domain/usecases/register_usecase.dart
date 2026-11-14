import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/auth/domain/entity/age_check_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/age_check_result.dart';
import 'package:skill_battles/features/auth/domain/entity/register_params_entity.dart';
import 'package:skill_battles/features/auth/domain/repository/auth_repository.dart';
import 'package:skill_battles/features/auth/domain/usecases/check_age_usecase.dart';

/// Re-runs the age pre-check, then signs up. The server decides finally.
final class RegisterUsecase
    implements
        Usecase<Future<Either<Failure, UserEntity>>, RegisterParamsEntity> {
  const RegisterUsecase({required this._repository, required this._checkAge});

  final AuthRepository _repository;
  final CheckAgeUsecase _checkAge;

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParamsEntity params) async {
    final AgeCheckResult age = _checkAge(
      AgeCheckParamsEntity(
        birthYear: params.birthYear,
        birthMonth: params.birthMonth,
        birthDay: params.birthDay,
      ),
    );
    switch (age) {
      case AgeCheckResult.eligible:
        return _repository.register(params);
      case AgeCheckResult.needsDay:
        return const Left(
          ValidationFailure(
            message: 'Enter your day of birth.',
            fieldErrors: <String, String>{
              ApiErrorCodes.birthDayField: 'Enter your day of birth.',
            },
          ),
        );
      case AgeCheckResult.restricted:
        return const Left(
          ValidationFailure(
            message: 'You must be at least 13 to use SkillBattles.',
          ),
        );
      case AgeCheckResult.invalidDate:
        return const Left(
          ValidationFailure(message: 'Enter a valid date of birth.'),
        );
    }
  }
}
