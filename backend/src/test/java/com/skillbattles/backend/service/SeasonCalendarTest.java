package com.skillbattles.backend.service;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import java.time.Instant;
import static org.assertj.core.api.Assertions.*;
class SeasonCalendarTest {
    @ParameterizedTest @CsvSource({
        "2026-12-01T04:59:59.999Z,FALL_2026,2026-09-01T04:00:00Z,2026-12-01T05:00:00Z",
        "2026-12-01T05:00:00Z,WINTER_2026,2026-12-01T05:00:00Z,2027-03-01T05:00:00Z",
        "2027-01-01T00:00:00Z,WINTER_2026,2026-12-01T05:00:00Z,2027-03-01T05:00:00Z",
        "2027-03-01T04:59:59.999Z,WINTER_2026,2026-12-01T05:00:00Z,2027-03-01T05:00:00Z",
        "2027-03-01T05:00:00Z,SPRING_2027,2027-03-01T05:00:00Z,2027-06-01T04:00:00Z",
        "2027-06-01T03:59:59.999Z,SPRING_2027,2027-03-01T05:00:00Z,2027-06-01T04:00:00Z",
        "2027-06-01T04:00:00Z,SUMMER_2027,2027-06-01T04:00:00Z,2027-09-01T04:00:00Z",
        "2027-09-01T04:00:00Z,FALL_2027,2027-09-01T04:00:00Z,2027-12-01T05:00:00Z"
    })
    void boundariesUseEtAndYearOfStartAcrossDst(String at,String code,String start,String end) {
        var season=SeasonCalendar.at(Instant.parse(at));
        assertThat(season.getId()).isEqualTo(code);assertThat(season.getStartsAt()).isEqualTo(Instant.parse(start));
        assertThat(season.getEndsAt()).isEqualTo(Instant.parse(end));assertThat(season.getTimezone()).isEqualTo("America/New_York");
        assertThat(SeasonCalendar.byId(code)).isEqualTo(season);
    }
}
