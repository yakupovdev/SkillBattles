package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class StatisticsProcessorImpl implements StatisticsProcessor {
    private final UserService userService;
    private final RatingService ratingService;

    @Override
    @Transactional(readOnly = true)
    public StatisticsDto getForUser(UUID userId) {
        userService.getById(userId);
        return new StatisticsDto(ratingService.getByUserId(userId).stream().map(rating ->
                new SubjectStatisticsDto(rating.getSubject(), rating.getRating(), rating.getRank(),
                        // No match results exist before the battle engine stage.
                        new MatchCountsDto(), new MatchCountsDto())).toList());
    }
}
