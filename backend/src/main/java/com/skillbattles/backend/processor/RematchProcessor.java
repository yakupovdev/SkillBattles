package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.RematchDto;import java.util.UUID;
public interface RematchProcessor {RematchDto request(UUID battle,UUID user);RematchDto get(UUID battle,UUID user);void cancel(UUID battle,UUID user);}
