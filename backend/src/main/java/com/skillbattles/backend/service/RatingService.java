package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.RatingDto;
import com.skillbattles.backend.dto.RatingUpdateDto;
import java.util.*;

public interface RatingService {
    void initialize(UUID userId);
    List<RatingDto> getByUserId(UUID userId);
    void settle(List<RatingUpdateDto> updates);
}
