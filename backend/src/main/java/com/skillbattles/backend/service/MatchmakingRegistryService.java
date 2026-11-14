package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.MatchmakingStateDto;
import java.util.function.Function;

public interface MatchmakingRegistryService {
    boolean hasWaiting();
    <T> T transact(Function<MatchmakingStateDto, T> operation);
}
