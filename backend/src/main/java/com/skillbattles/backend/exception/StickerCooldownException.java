package com.skillbattles.backend.exception;
import java.time.*;
import lombok.Getter;
import org.springframework.http.HttpStatus;
@Getter
public class StickerCooldownException extends BusinessException {
    private final Instant resetsAt;
    private final long retryAfter;
    public StickerCooldownException(Instant now, Instant resetsAt) {
        super("STICKER_COOLDOWN", "Wait before sending another sticker.", HttpStatus.TOO_MANY_REQUESTS);
        this.resetsAt = resetsAt;
        Duration remaining = Duration.between(now, resetsAt);
        this.retryAfter = Math.max(1, remaining.getSeconds() + (remaining.getNano() == 0 ? 0 : 1));
    }
}
