package com.skillbattles.backend.service;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import java.time.*;
import java.util.*;
import static org.assertj.core.api.Assertions.*;
class StreakCalculatorTest {
    @ParameterizedTest @CsvSource({"2026-03-08T05:00:00Z,2026-03-09T04:00:00Z,23","2026-11-01T04:00:00Z,2026-11-02T05:00:00Z,25"})
    void nextMidnightUsesDst(String now,String next,int hours) {
        var at=Instant.parse(now);assertThat(EtCalendar.resetsAt(at)).isEqualTo(Instant.parse(next));
        assertThat(Duration.between(at,EtCalendar.resetsAt(at)).toHours()).isEqualTo(hours);
    }
    @Test void dailyDuplicatesDoNotExtendAndMissedDayBreaksCurrentButKeepsBest() {
        var a=LocalDate.of(2026,11,9);var days=List.of(a,a,a.plusDays(1),a.plusDays(2),a.plusDays(4));
        assertThat(StreakCalculator.calculate(days,a.plusDays(4)).getDailyCurrent()).isEqualTo(1);
        assertThat(StreakCalculator.calculate(days,a.plusDays(5)).getDailyCurrent()).isEqualTo(1);
        var expired=StreakCalculator.calculate(days,a.plusDays(6));assertThat(expired.getDailyCurrent()).isZero();assertThat(expired.getDailyBest()).isEqualTo(3);
    }
    @Test void onlyCompletedFourDayWeeksCountAndCurrentWeekOnlyShowsRealProgress() {
        var monday=LocalDate.of(2026,11,2);List<LocalDate> days=new ArrayList<>();
        for(int week=0;week<3;week++)for(int d=0;d<4;d++)days.add(monday.plusWeeks(week).plusDays(d));
        var ongoing=StreakCalculator.calculate(days,monday.plusWeeks(2).plusDays(3));
        assertThat(ongoing.getWeeklyCurrent()).isEqualTo(2);assertThat(ongoing.getCurrentWeekActiveDays()).isEqualTo(4);
        assertThat(StreakCalculator.calculate(days,monday.plusWeeks(3)).getWeeklyCurrent()).isEqualTo(3);
        var broken=StreakCalculator.calculate(days,monday.plusWeeks(4));assertThat(broken.getWeeklyCurrent()).isZero();assertThat(broken.getWeeklyBest()).isEqualTo(3);
    }
    @Test void emptyAndFutureDatesDoNotProduceFakeStreaks() {
        var day=LocalDate.of(2026,11,9);var s=StreakCalculator.calculate(List.of(day.plusDays(1)),day);
        assertThat(s.getLastQualifiedDate()).isNull();assertThat(s.getDailyCurrent()).isZero();assertThat(s.getDailyBest()).isZero();assertThat(s.getWeeklyCurrent()).isZero();
    }
}
