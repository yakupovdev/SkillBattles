package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.RatingDto;
import com.skillbattles.backend.dto.RatingUpdateDto;
import java.util.*;

public interface RatingService {
    java.util.List<com.skillbattles.backend.dto.LeaderboardRowDto> leaderboard(String code,String season,UUID user);
    List<UUID> rolloverCandidates(String code,String season);
    void initialize(UUID userId);
    List<RatingDto> getByUserId(UUID userId);
    List<RatingDto> lockForUser(UUID userId);
    void rollover(RatingDto expected,String nextSeasonId,int resetRating);
    void settle(List<RatingUpdateDto> updates);
}
