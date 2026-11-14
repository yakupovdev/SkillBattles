package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.SeasonDto;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
/** Calendar quarters start at midnight ET; UTC lengths include DST changes. */
public final class SeasonCalendar {
    public static final ZoneId ZONE=ZoneId.of("America/New_York");
    private SeasonCalendar() { }
    public static SeasonDto at(Instant instant) {
        LocalDate date=instant.atZone(ZONE).toLocalDate();
        int month=date.getMonthValue();
        int startMonth=month<3?12:month<6?3:month<9?6:month<12?9:12;
        int year=date.getYear()-(month<3?1:0);
        LocalDate start=LocalDate.of(year,startMonth,1);
        String name=switch(startMonth) {case 3 -> "Spring";case 6 -> "Summer";case 9 -> "Fall";default -> "Winter";};
        return new SeasonDto(name.toUpperCase(Locale.ROOT)+"_"+year,name+" "+year,start.atStartOfDay(ZONE).toInstant(),start.plusMonths(3).atStartOfDay(ZONE).toInstant(),ZONE.getId());
    }
    public static SeasonDto byId(String id) {
        String[] parts=id.split("_");
        int month=switch(parts[0]) {case "SPRING" -> 3;case "SUMMER" -> 6;case "FALL" -> 9;case "WINTER" -> 12;default -> throw new IllegalArgumentException("Invalid season ID.");};
        return at(LocalDate.of(Integer.parseInt(parts[1]),month,1).atStartOfDay(ZONE).toInstant());
    }
}
