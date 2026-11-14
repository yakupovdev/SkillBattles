package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.RatingDto;
import java.util.*;
public interface RatingProcessor {
    List<RatingDto> prepare(UUID userId);
    List<RatingDto> prepare(UUID userId,com.skillbattles.backend.dto.SeasonDto season);
}
