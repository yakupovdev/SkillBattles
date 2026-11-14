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
    private final RatingProcessor ratingProcessor;
    private final RankService ranks;
    private final SubscriptionService subscriptions;
    private final StreakService streaks;

    @Override
    @Transactional
    public StatisticsDto getForUser(UUID userId) {
        userService.getById(userId);
        var current=ratingProcessor.prepare(userId);
        var history=battleService.finishedHistory(userId);
        var entitlement=subscriptions.entitlements(userId);
        var tiers=ranks.tiers();
        return new StatisticsDto(current.stream().map(rating -> {
            var dto=new DisciplineStatisticsDto();dto.setDisciplineCode(rating.getDisciplineCode());dto.setRating(rating.getRating());
            var rank=RankCalculator.fromRating(tiers,rating.getRating());
            dto.setRank(new RankProgressDto(rank.getCode(),rank.getDisplayName(),rank.getLeagueCode(),rating.getRating()-rank.getFloorRating(),
                    rank.getCeilingExclusive()==null?null:rank.getCeilingExclusive()-rank.getFloorRating(),rank.getFloorRating(),rank.getCeilingExclusive()));
            int completed=rating.getCalibrationCompletedMatches();
            dto.setCalibration(new CalibrationDto(completed,Math.max(0,5-completed),completed<5,completed<5?64:32));
            dto.setAllTimePeakRating(rating.getAllTimePeakRating());dto.setAllTimePeakRankCode(RankCalculator.fromRating(tiers,rating.getAllTimePeakRating()).getCode());
            dto.setSeasonId(rating.getSeasonId());dto.setSeasonPeakRating(rating.getSeasonPeakRating());
            dto.setSeasonPeakRankCode(RankCalculator.fromRating(tiers,rating.getSeasonPeakRating()).getCode());dto.setSeasonRolloverPending(rating.isSeasonRolloverPending());
            var disciplineHistory=history.stream().filter(b -> b.getDisciplineCode().equals(rating.getDisciplineCode())).toList();
            dto.setRanked(StatisticsCalculator.matches(disciplineHistory,userId,BattleMode.RANKED));
            dto.setPrivateMatches(StatisticsCalculator.matches(disciplineHistory,userId,BattleMode.PRIVATE));
            if(entitlement.isPro()){dto.setTopicStats(StatisticsCalculator.topics(disciplineHistory,userId));dto.setRatingHistory(StatisticsCalculator.ratings(disciplineHistory,userId));}
            return dto;
        }).toList(),entitlement,streaks.current(userId));
    }
}
