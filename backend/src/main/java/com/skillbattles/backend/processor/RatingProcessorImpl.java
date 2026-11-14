package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.math.*;
import java.util.*;
/** Serializes season archives and soft resets on rating rows, without locking battle rows. */
@Component @RequiredArgsConstructor
public class RatingProcessorImpl implements RatingProcessor {
    private final RatingService ratings;
    private final SeasonService seasons;
    private final BattleService battles;
    private final RankService ranks;
    @Override @Transactional public List<RatingDto> prepare(UUID userId) {
        return prepare(userId,seasons.current());
    }
    @Override @Transactional public List<RatingDto> prepare(UUID userId,SeasonDto current) {
        ratings.initialize(userId);
        var tiers=ranks.tiers();
        for(var rating:ratings.lockForUser(userId)) {
            if(rating.getSeasonId().equals(current.getId())) continue;
            if(battles.hasActiveRankedBattle(userId,rating.getDisciplineCode())) continue;
            var previous=SeasonCalendar.byId(rating.getSeasonId());
            while(previous.getEndsAt().compareTo(current.getStartsAt())<=0) {
                seasons.archive(new SeasonArchiveDto(userId,previous.getId(),previous,rating.getDisciplineCode(),rating.getSeasonPeakRating(),
                        RankCalculator.fromRating(tiers,rating.getSeasonPeakRating()).getCode(),rating.getRating()));
                int reset=BigDecimal.valueOf(1000).add(BigDecimal.valueOf(rating.getRating()-1000).multiply(new BigDecimal("0.5"))).setScale(0,RoundingMode.HALF_UP).intValueExact();
                var next=SeasonCalendar.at(previous.getEndsAt());
                ratings.rollover(rating,next.getId(),reset);
                rating.setRating(reset);rating.setSeasonId(next.getId());rating.setSeasonPeakRating(reset);
                previous=next;
            }
        }
        return ratings.getByUserId(userId).stream().peek(r -> r.setSeasonRolloverPending(!r.getSeasonId().equals(current.getId()))).toList();
    }
}
