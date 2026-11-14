package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.StreaksDto;
import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
public final class StreakCalculator {
    private StreakCalculator() { }
    public static StreaksDto calculate(Collection<LocalDate> dates,LocalDate today) {
        var days=new TreeSet<>(dates);days.removeIf(d -> d.isAfter(today));
        int best=0,run=0;LocalDate previous=null;
        Map<LocalDate,Integer> weeks=new TreeMap<>();var monday=today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        for(var day:days) {run=previous!=null&&day.equals(previous.plusDays(1))?run+1:1;best=Math.max(best,run);previous=day;
            weeks.merge(day.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)),1,Integer::sum);}
        int daily=previous!=null&&!previous.isBefore(today.minusDays(1))?run:0;
        int weekly=0,weeklyBest=0;LocalDate lastWeek=null;
        for(var week:weeks.keySet()) {
            if(!week.isBefore(monday)) break;
            if(weeks.get(week)>=4) {weekly=lastWeek!=null&&week.equals(lastWeek.plusWeeks(1))?weekly+1:1;weeklyBest=Math.max(weeklyBest,weekly);lastWeek=week;}
            else {weekly=0;lastWeek=null;}
        }
        if(lastWeek==null||!lastWeek.equals(monday.minusWeeks(1)))weekly=0;
        return new StreaksDto(EtCalendar.ZONE.getId(),daily,best,previous,weekly,weeklyBest,monday,weeks.getOrDefault(monday,0),4);
    }
}
