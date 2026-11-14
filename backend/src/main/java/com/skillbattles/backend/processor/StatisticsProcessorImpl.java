package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.BattleMode;
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
    private final BattleService battleService;

    @Override
    @Transactional(readOnly = true)
    public StatisticsDto getForUser(UUID userId) {
        userService.getById(userId);
        var results = battleService.statistics(userId);
        return new StatisticsDto(ratingService.getByUserId(userId).stream().map(rating ->
                new SubjectStatisticsDto(rating.getSubject(), rating.getRating(), rating.getRank(),
                        results.stream().filter(item -> item.getSubject() == rating.getSubject() && item.getMode() == BattleMode.RANKED)
                                .map(BattleCountsDto::getCounts).findFirst().orElseGet(MatchCountsDto::new),
                        results.stream().filter(item -> item.getSubject() == rating.getSubject() && item.getMode() == BattleMode.PRIVATE)
                                .map(BattleCountsDto::getCounts).findFirst().orElseGet(MatchCountsDto::new))).toList());
    }
}
