package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.StreaksDto;
import java.time.Instant;
import java.util.UUID;
public interface StreakService {boolean qualify(UUID userId,Instant finishedAt);StreaksDto current(UUID userId);}
