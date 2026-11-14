package com.skillbattles.backend.service;
import java.time.*;
import java.util.*;
public interface UsageService {
    int used(UUID userId,LocalDate day);
    boolean start(UUID battleId,Map<UUID,Boolean> pro,Instant at);
    boolean refund(UUID battleId);
}
