package com.skillbattles.backend.service;
import java.time.*;
public final class EtCalendar {
    public static final ZoneId ZONE=ZoneId.of("America/New_York");
    private EtCalendar() { }
    public static LocalDate date(Instant at) {return at.atZone(ZONE).toLocalDate();}
    public static Instant resetsAt(Instant at) {return date(at).plusDays(1).atStartOfDay(ZONE).toInstant();}
}
