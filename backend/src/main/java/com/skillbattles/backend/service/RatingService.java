package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.RatingDto;
import com.skillbattles.backend.dto.RatingUpdateDto;
import java.util.*;

public interface RatingService {
    void initialize(UUID userId);
    List<RatingDto> getByUserId(UUID userId);
    List<RatingDto> lockForUser(UUID userId);
    void rollover(RatingDto expected,String nextSeasonId,int resetRating);
    void settle(List<RatingUpdateDto> updates);
}
