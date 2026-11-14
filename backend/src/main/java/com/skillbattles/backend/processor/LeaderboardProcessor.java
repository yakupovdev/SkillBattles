package com.skillbattles.backend.processor;
import java.util.UUID;import com.skillbattles.backend.dto.LeaderboardResponse;
public interface LeaderboardProcessor {LeaderboardResponse get(String code,UUID user);}
