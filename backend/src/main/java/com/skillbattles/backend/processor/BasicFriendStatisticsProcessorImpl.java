package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.BattleMode;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Component @RequiredArgsConstructor
public class BasicFriendStatisticsProcessorImpl implements BasicFriendStatisticsProcessor {
    private final RatingProcessor ratings;
    private final BattleService battles;
    private final RankService ranks;
    @Override @Transactional public List<FriendDisciplineStatisticsDto> statistics(UUID user){
        var current=ratings.prepare(user);var history=battles.finishedHistory(user);var tiers=ranks.tiers();
        return current.stream().map(r->{
            var dto=new FriendDisciplineStatisticsDto();dto.setDisciplineCode(r.getDisciplineCode());dto.setRating(r.getRating());
            var rank=RankCalculator.fromRating(tiers,r.getRating());
            dto.setRank(new RankProgressDto(rank.getCode(),rank.getDisplayName(),rank.getLeagueCode(),r.getRating()-rank.getFloorRating(),rank.getCeilingExclusive()==null?null:rank.getCeilingExclusive()-rank.getFloorRating(),rank.getFloorRating(),rank.getCeilingExclusive()));
            int completed=r.getCalibrationCompletedMatches();dto.setCalibration(new CalibrationDto(completed,Math.max(0,5-completed),completed<5,completed<5?64:32));
            dto.setAllTimePeakRating(r.getAllTimePeakRating());dto.setAllTimePeakRankCode(RankCalculator.fromRating(tiers,r.getAllTimePeakRating()).getCode());
            dto.setSeasonId(r.getSeasonId());dto.setSeasonPeakRating(r.getSeasonPeakRating());dto.setSeasonPeakRankCode(RankCalculator.fromRating(tiers,r.getSeasonPeakRating()).getCode());dto.setSeasonRolloverPending(r.isSeasonRolloverPending());
            var relevant=history.stream().filter(b->b.getDisciplineCode().equals(r.getDisciplineCode())).toList();
            dto.setRanked(StatisticsCalculator.matches(relevant,user,BattleMode.RANKED));dto.setPrivateMatches(StatisticsCalculator.matches(relevant,user,BattleMode.PRIVATE));return dto;
        }).toList();
    }
}
