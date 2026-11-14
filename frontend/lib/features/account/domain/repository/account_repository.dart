import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/account_state_entity.dart';
import 'package:skill_battles/features/account/domain/entity/activity_entity.dart';
import 'package:skill_battles/features/account/domain/entity/limits_entity.dart';
import 'package:skill_battles/features/account/domain/entity/season_history_page_entity.dart';
import 'package:skill_battles/features/account/domain/entity/season_history_params_entity.dart';
import 'package:skill_battles/features/account/domain/entity/statistics_entity.dart';
import 'package:skill_battles/features/account/domain/entity/update_profile_params_entity.dart';
import 'package:skill_battles/features/account/domain/entity/update_profile_result_entity.dart';

abstract interface class AccountRepository {
  Future<Either<Failure, UserEntity>> getMe();

  /// After a password change the local session is cleared.
  Future<Either<Failure, UpdateProfileResultEntity>> updateProfile(
    UpdateProfileParamsEntity params,
  );

  Future<Either<Failure, StatisticsEntity>> getStatistics();

  Future<Either<Failure, LimitsEntity>> getLimits();

  Future<Either<Failure, ActivityEntity>> getActivity();

  Future<Either<Failure, SeasonHistoryPageEntity>> getSeasonHistory(
    SeasonHistoryParamsEntity params,
  );

  /// Profile, verified subscription and limits read together.
  Future<Either<Failure, AccountStateEntity>> getAccountState();

  /// ACCOUNT_CHANGED notifications of the signed-in account.
  Stream<AccountStateEntity> watchAccountChanges();
}
