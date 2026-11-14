package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.RatingDto;
import com.skillbattles.backend.dto.RatingUpdateDto;
import com.skillbattles.backend.mapper.RatingMapper;
import com.skillbattles.backend.repository.RatingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RatingServiceImpl implements RatingService {
    private final RatingRepository repository;
    private final RatingMapper mapper;
    private final DisciplineService disciplines;
    private final RankService ranks;
    private final SeasonService seasons;
    private final java.time.Clock clock;

    @Override public List<UUID> rolloverCandidates(String code,String season){return repository.rolloverCandidates(code,season);}
    @Override public List<com.skillbattles.backend.dto.LeaderboardRowDto> leaderboard(String code,String season,UUID user){return repository.leaderboard(code,season,user).stream().map(r->new com.skillbattles.backend.dto.LeaderboardRowDto(r.getPosition(),r.getUserId(),r.getNickname(),r.getRating(),r.getCalibrationCompletedMatches())).toList();}
    @Override
    @Transactional
    public void initialize(UUID userId) {
        disciplines.active().forEach(discipline -> repository.initializeMissing(userId, discipline.getCode(), seasons.current().getId(), clock.instant()));
    }

    @Override
    public List<RatingDto> getByUserId(UUID userId) {
        var active = disciplines.active().stream().map(com.skillbattles.backend.dto.DisciplineDto::getCode).toList();
        var tiers = ranks.tiers();
        return repository.findAllByUserId(userId).stream().filter(rating -> active.contains(rating.getDisciplineCode()))
                .sorted(Comparator.comparingInt(rating -> active.indexOf(rating.getDisciplineCode())))
                .map(mapper::toDto).peek(dto -> { var rank = RankCalculator.fromRating(tiers, dto.getRating()); dto.setRankCode(rank.getCode()); dto.setRankName(rank.getDisplayName()); }).toList();
    }

    @Override @Transactional
    public List<RatingDto> lockForUser(UUID userId) {return repository.lockByUserId(userId).stream().map(mapper::toDto).toList();}

    @Override @Transactional
    public void rollover(RatingDto expected,String nextSeasonId,int resetRating) {
        var rating=repository.lockForSettlement(List.of(expected.getUserId()),expected.getDisciplineCode()).stream().findFirst().orElseThrow();
        if(!rating.getSeasonId().equals(expected.getSeasonId()) || rating.getRating()!=expected.getRating()) throw new IllegalStateException("Rating changed during rollover.");
        rating.setRatingReachedAt(clock.instant());
        rating.setRating(resetRating); rating.setSeasonId(nextSeasonId); rating.setSeasonPeakRating(resetRating);
        // A seasonal reset must never create an artificial lifetime peak.
        repository.flush();
    }

    @Override
    @Transactional
    public void settle(List<RatingUpdateDto> updates) {
        if (updates.size() != 2 || updates.get(0).getUserId().equals(updates.get(1).getUserId())
                || !updates.get(0).getDisciplineCode().equals(updates.get(1).getDisciplineCode())) {
            throw new IllegalArgumentException("Settlement requires two distinct users in the same disciplineCode.");
        }
        var locked = repository.lockForSettlement(updates.stream().map(RatingUpdateDto::getUserId).toList(), updates.getFirst().getDisciplineCode());
        if (locked.size() != 2) throw new IllegalStateException("Missing participant ratings.");
        for (var rating : locked) {
            var update = updates.stream().filter(item -> item.getUserId().equals(rating.getUserId())).findFirst().orElseThrow();
            if (rating.getRating() != update.getBefore() || update.getAfter() < 0 || !rating.getSeasonId().equals(update.getSeasonId()) || rating.getCalibrationCompletedMatches()!=update.getCompletedMatchesBefore()) throw new IllegalStateException("Participant rating changed during the battle.");
            if(rating.getRating()!=update.getAfter())rating.setRatingReachedAt(clock.instant());
            rating.setRating(update.getAfter());
            rating.setCalibrationCompletedMatches(Math.addExact(rating.getCalibrationCompletedMatches(),1));
            rating.setSeasonPeakRating(Math.max(rating.getSeasonPeakRating(),update.getAfter()));
            rating.setAllTimePeakRating(Math.max(rating.getAllTimePeakRating(),update.getAfter()));
        }
        repository.flush();
    }
}
