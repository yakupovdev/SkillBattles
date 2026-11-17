import 'package:test/test.dart';

import 'package:skill_battles/core/utils/time/clock.dart';
import 'package:skill_battles/features/auth/domain/entity/age_check_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/age_check_result.dart';
import 'package:skill_battles/features/auth/domain/usecases/check_age_usecase.dart';

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  // 2026-11-15 03:00 UTC is still 2026-11-14 22:00 in New York (EST).
  final CheckAgeUsecase checkAge = CheckAgeUsecase(
    _FixedClock(DateTime.utc(2026, 11, 15, 3)),
  );

  AgeCheckResult check(int year, int month, [int? day]) => checkAge(
    AgeCheckParamsEntity(birthYear: year, birthMonth: month, birthDay: day),
  );

  test('13+ by month and year is eligible without a day', () {
    expect(check(2013, 10), AgeCheckResult.eligible);
    expect(check(2000, 1), AgeCheckResult.eligible);
  });

  test('younger than 13 by month and year is restricted', () {
    expect(check(2013, 12), AgeCheckResult.restricted);
    expect(check(2015, 1), AgeCheckResult.restricted);
  });

  test('turning 13 in the current ET month needs the day', () {
    expect(check(2013, 11), AgeCheckResult.needsDay);
  });

  test('the day decides on the ET date, exactly 13 today is allowed', () {
    // ET date is the 14th, not the UTC 15th.
    expect(check(2013, 11, 14), AgeCheckResult.eligible);
    expect(check(2013, 11, 15), AgeCheckResult.restricted);
  });

  test('future and non-existent dates are invalid', () {
    expect(check(2027, 1), AgeCheckResult.invalidDate);
    expect(check(2026, 11, 20), AgeCheckResult.invalidDate);
    expect(check(2010, 2, 30), AgeCheckResult.invalidDate);
    expect(check(1899, 5), AgeCheckResult.invalidDate);
    expect(check(2000, 13), AgeCheckResult.invalidDate);
  });
}
