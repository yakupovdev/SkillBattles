package com.skillbattles.backend.exception;
import lombok.Getter;
import org.springframework.http.HttpStatus;
import java.time.Instant;
@Getter
public class DailyLimitException extends BusinessException {
    private final Instant resetsAt;
    public DailyLimitException(Instant resetsAt) {super("DAILY_LIMIT_REACHED","Daily ranked limit reached.",HttpStatus.TOO_MANY_REQUESTS);this.resetsAt=resetsAt;}
}
