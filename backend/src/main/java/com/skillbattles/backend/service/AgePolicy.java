package com.skillbattles.backend.service;

import com.skillbattles.backend.exception.*;
import java.time.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component @RequiredArgsConstructor
public class AgePolicy {
    private final Clock clock;
    public void validate(Integer year, Integer month, Integer day) {
        LocalDate today = EtCalendar.date(clock.instant());
        try {
            if (year == null || month == null || year < 1900) throw new DateTimeException("Invalid birth date");
            YearMonth birth = YearMonth.of(year, month);
            if (day != null) birth.atDay(day);
            if (birth.isAfter(YearMonth.from(today)) || (day != null && birth.atDay(day).isAfter(today)))
                throw new DateTimeException("Future birth date");
            YearMonth boundary = YearMonth.from(today.minusYears(13));
            if (birth.equals(boundary) && day == null) throw new FieldValidationException("birthDay", "Birth day is required in the month of your thirteenth birthday.");
            if (birth.isAfter(boundary) || (birth.equals(boundary) && day > today.getDayOfMonth()))
                throw new AgeRestrictedException();
        } catch (DateTimeException ex) {
            throw new FieldValidationException("birthYear", "A valid, non-future birth date is required.");
        }
    }
}
