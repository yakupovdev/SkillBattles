package com.skillbattles.backend.service;
import java.time.*;
import java.util.*;
import org.springframework.stereotype.Component;
import lombok.RequiredArgsConstructor;
import com.skillbattles.backend.exception.RateLimitedException;
/** Single-process fixed window limiter. Remote address comes from the socket, never an untrusted forwarded header. */
@Component @RequiredArgsConstructor public class RequestRateLimiter {
 private final Clock clock; private final Map<String,Window> windows=new HashMap<>();
 public synchronized void check(String key,int limit) {
  Instant now=clock.instant();windows.entrySet().removeIf(e -> !e.getValue().until.isAfter(now));
  Window w=windows.computeIfAbsent(key,k -> new Window(now.plusSeconds(1200)));
  if(w.count>=limit)throw new RateLimitedException(Math.max(1,Duration.between(now,w.until).getSeconds()));
  w.count++;
 }
 private static class Window { final Instant until; int count; Window(Instant until){this.until=until;} }
}
