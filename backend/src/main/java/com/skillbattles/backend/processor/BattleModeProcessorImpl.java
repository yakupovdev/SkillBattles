package com.skillbattles.backend.processor;

import com.skillbattles.backend.config.BattleProperties;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Component @RequiredArgsConstructor
public class BattleModeProcessorImpl implements BattleModeProcessor {
    private final QuestionService questions;
    private final BattleProperties properties;
    private final DisciplineService disciplines;
    private final RatingService ratings;
    private final UserService users;
    private final RatingProcessor ratingProcessor;

    @Override @Transactional public void initializeActiveRatings() { users.activeIds().forEach(ratings::initialize); }

    @Override @Transactional public List<BattleModeDto> getModes(UUID userId) {
        users.getById(userId);
        var own = ratingProcessor.prepare(userId);
        return disciplines.active().stream().map(discipline -> {
            int rating = own.stream().filter(r -> r.getDisciplineCode().equals(discipline.getCode())).findFirst().orElseThrow().getRating();
            Map<Difficulty, Long> counts = new EnumMap<>(Difficulty.class);
            for (var difficulty : Difficulty.values()) counts.put(difficulty, questions.countAvailable(discipline.getCode(), difficulty));
            var dto = new BattleModeDto();
            dto.setDisciplineCode(discipline.getCode()); dto.setDisplayName(discipline.getDisplayName()); dto.setDescription(discipline.getDescription());
            dto.setActive(discipline.isActive()); dto.setFormat(discipline.getFormat()); dto.setQuestionType(discipline.getQuestionType());
            dto.setOptionsCount(discipline.getOptionsCount()); dto.setQuestionCount(discipline.getQuestionCount()); dto.setBaseQuestionSeconds(discipline.getBaseQuestionSeconds());
            dto.setOvertimeSeconds(discipline.getOvertimeSeconds()); dto.setReadyTimeoutSeconds(properties.getReadyTimeoutSeconds());
            dto.setCountdownSeconds(properties.getCountdownSeconds()); dto.setRevealSeconds(properties.getRevealSeconds()); dto.setReconnectGraceSeconds(properties.getReconnectGraceSeconds());
            dto.setDifficultyTimings(discipline.getTimings().stream().map(t -> {
                var timing = new DifficultyTiming(); timing.setDifficulty(t.getDifficulty()); timing.setLimitSeconds(disciplines.limitSeconds(discipline, t.getDifficulty())); timing.setBasePoints(t.getBasePoints()); return timing;
            }).toList());
            dto.setDifficultySchedules(discipline.getSchedules().stream().map(s -> {
                var schedule = new DifficultySchedule(); schedule.setMinRating(s.getMinRating()); schedule.setMaxRatingExclusive(s.getMaxRatingExclusive());
                schedule.setRoundDifficulties(s.getRoundDifficulties()); schedule.setContentAvailable(DisciplineContentPolicy.available(s, counts)); return schedule;
            }).toList());
            dto.setContentAvailable(dto.getDifficultySchedules().stream().anyMatch(s -> s.getMinRating() <= rating && s.isContentAvailable()));
            return dto;
        }).toList();
    }
}
