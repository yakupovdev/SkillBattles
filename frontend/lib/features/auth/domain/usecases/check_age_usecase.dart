import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/time/clock.dart';
import 'package:skill_battles/core/utils/time/eastern_time.dart';
import 'package:skill_battles/features/auth/domain/entity/age_check_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/age_check_result.dart';

/// Pre-checks the birth input against today's ET date: 13+ may continue;
/// turning 13 this ET month needs the day; exactly 13 today is allowed.
final class CheckAgeUsecase
    implements Usecase<AgeCheckResult, AgeCheckParamsEntity> {
  const CheckAgeUsecase(this._clock);

  final Clock _clock;

  static const int minimumAge = 13;
  static const int minimumYear = 1900;

  @override
  AgeCheckResult call(AgeCheckParamsEntity params) {
    final DateTime today = EasternTime.dateOf(_clock.now());
    final int year = params.birthYear;
    final int month = params.birthMonth;
    final int? day = params.birthDay;
    if (year < minimumYear || month < 1 || month > 12) {
      return AgeCheckResult.invalidDate;
    }
    final int monthsOld = (today.year - year) * 12 + (today.month - month);
    if (monthsOld < 0) return AgeCheckResult.invalidDate;
    if (day != null) {
      final int daysInMonth = DateTime.utc(year, month + 1, 0).day;
      if (day < 1 || day > daysInMonth) return AgeCheckResult.invalidDate;
      if (monthsOld == 0 && day > today.day) return AgeCheckResult.invalidDate;
    }
    const int thresholdMonths = minimumAge * 12;
    if (monthsOld > thresholdMonths) return AgeCheckResult.eligible;
    if (monthsOld < thresholdMonths) return AgeCheckResult.restricted;
    if (day == null) return AgeCheckResult.needsDay;
    return today.day >= day
        ? AgeCheckResult.eligible
        : AgeCheckResult.restricted;
  }
}
