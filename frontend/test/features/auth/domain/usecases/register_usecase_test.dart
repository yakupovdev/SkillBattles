import 'package:test/test.dart';

import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/core/utils/time/clock.dart';
import 'package:skill_battles/features/auth/domain/entity/login_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/password_reset_confirm_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/password_reset_request_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/register_params_entity.dart';
import 'package:skill_battles/features/auth/domain/repository/auth_repository.dart';
import 'package:skill_battles/features/auth/domain/usecases/check_age_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/register_usecase.dart';

final class _Clock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 11, 14, 17);
}

final class _Repository implements AuthRepository {
  final List<RegisterParamsEntity> registered = <RegisterParamsEntity>[];

  @override
  Future<Either<Failure, UserEntity>> register(
    RegisterParamsEntity params,
  ) async {
    registered.add(params);
    return Right(
      UserEntity(
        id: 'u',
        email: params.email,
        nickname: params.nickname,
        createdAt: DateTime.utc(2026),
        isPro: false,
      ),
    );
  }

  @override
  Future<Either<Failure, UserEntity>> login(LoginParamsEntity params) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> logout() => throw UnimplementedError();

  @override
  Future<Either<Failure, String>> requestPasswordReset(
    PasswordResetRequestParamsEntity params,
  ) => throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> confirmPasswordReset(
    PasswordResetConfirmParamsEntity params,
  ) => throw UnimplementedError();

  @override
  Stream<bool> watchSignedIn() => const Stream<bool>.empty();

  @override
  bool get isSignedIn => false;
}

RegisterParamsEntity _params(int year, int month, [int? day]) =>
    RegisterParamsEntity(
      email: 'a@b.co',
      password: 'Password1!',
      nickname: 'alex',
      birthYear: year,
      birthMonth: month,
      birthDay: day,
    );

void main() {
  late _Repository repository;
  late RegisterUsecase register;

  setUp(() {
    repository = _Repository();
    register = RegisterUsecase(
      repository: repository,
      checkAge: CheckAgeUsecase(_Clock()),
    );
  });

  test('an eligible birth date is forwarded to the repository', () async {
    final Either<Failure, UserEntity> result = await register(_params(2008, 9));

    expect(result.isRight(), isTrue);
    expect(repository.registered.single.birthDay, isNull);
  });

  test(
    'a missing day near the 13th birthday is a birthDay field error',
    () async {
      final Either<Failure, UserEntity> result = await register(
        _params(2013, 11),
      );

      final Failure failure = result.getLeft()!;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        contains('birthDay'),
      );
      expect(repository.registered, isEmpty);
    },
  );

  test('under 13 never reaches the repository', () async {
    final Either<Failure, UserEntity> result = await register(_params(2014, 1));

    expect(result.isLeft(), isTrue);
    expect(repository.registered, isEmpty);
  });
}
