package com.skillbattles.backend.exception;
import lombok.Getter;
import org.springframework.http.HttpStatus;
@Getter public class RateLimitedException extends BusinessException {
 private final long retryAfter;
 public RateLimitedException(long retryAfter){super("RATE_LIMITED","Too many requests. Try again later.",HttpStatus.TOO_MANY_REQUESTS);this.retryAfter=retryAfter;}
}
