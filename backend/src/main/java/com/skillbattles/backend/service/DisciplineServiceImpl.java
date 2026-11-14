package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.mapper.DisciplineMapper;
import com.skillbattles.backend.repository.DisciplineRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.*;

@Service @RequiredArgsConstructor @Transactional(readOnly = true)
public class DisciplineServiceImpl implements DisciplineService {
    private final DisciplineRepository repository;
    private final DisciplineMapper mapper;
    @Override public List<DisciplineDto> active() { return repository.findByActiveTrueOrderByDisplayOrderAscCodeAsc().stream().map(mapper::toDto).peek(this::validate).toList(); }
    @Override public DisciplineDto get(String code) {
        if (code == null || !code.matches("[A-Z][A-Z0-9_]{1,63}")) throw new BusinessValidationException("VALIDATION_ERROR", "Invalid discipline code.");
        DisciplineDto dto = repository.findByCode(code).map(mapper::toDto).orElseThrow(() -> new ConflictException("DISCIPLINE_UNAVAILABLE", "Discipline is unavailable."));
        validate(dto); return dto;
    }
    @Override public DisciplineDto requireActive(String code) {
        var dto = get(code);
        if (!dto.isActive()) throw new ConflictException("DISCIPLINE_UNAVAILABLE", "Discipline is unavailable.");
        return dto;
    }
    @Override @Transactional public void mergeTopics(String code, List<TopicDto> topics) {
        var entity = repository.lockByCode(code).orElseThrow(() -> new ConflictException("DISCIPLINE_UNAVAILABLE", "Discipline is unavailable."));
        Map<String, String> names = new TreeMap<>();
        entity.getTopics().forEach(topicName -> names.put(topicName.getTopicCode(), topicName.getTopicName()));
        topics.forEach(topicName -> names.put(topicName.getTopicCode(), topicName.getTopicName()));
        var merged = names.entrySet().stream().map(entry -> new TopicDto(entry.getKey(), entry.getValue())).toList();
        if (!merged.equals(entity.getTopics())) entity.setTopics(merged);
    }
    @Override public int limitSeconds(DisciplineDto dto, Difficulty difficulty) {
        var timing = dto.getTimings().stream().filter(item -> item.getDifficulty() == difficulty).findFirst().orElseThrow();
        return BigDecimal.valueOf(dto.getBaseQuestionSeconds()).multiply(timing.getTimeMultiplier()).intValueExact();
    }
    private void validate(DisciplineDto dto) {
        boolean valid = dto.getFormat() == BattleFormat.STANDARD && dto.getQuestionType() == QuestionType.SINGLE_CHOICE
                && dto.getOptionsCount() == 4 && dto.getQuestionCount() == 5 && dto.getBaseQuestionSeconds() > 0 && dto.getOvertimeSeconds() > 0
                && dto.getTimings() != null && dto.getTimings().size() == Difficulty.values().length && dto.getSchedules() != null && !dto.getSchedules().isEmpty();
        if (!valid) invalid();
        Set<Difficulty> found = EnumSet.noneOf(Difficulty.class);
        for (var timing : dto.getTimings()) {
            if (timing.getDifficulty() == null || !found.add(timing.getDifficulty()) || timing.getTimeMultiplier() == null || timing.getTimeMultiplier().signum() <= 0 || timing.getBasePoints() < 0) invalid();
            try { if (limitSeconds(dto, timing.getDifficulty()) < 1) invalid(); } catch (ArithmeticException ex) { invalid(); }
        }
        int floor = 0;
        for (int index = 0; index < dto.getSchedules().size(); index++) {
            var schedule = dto.getSchedules().get(index);
            if (schedule.getMinRating() != floor || schedule.getRoundDifficulties() == null || schedule.getRoundDifficulties().size() != 5
                    || schedule.getRoundDifficulties().contains(null)) invalid();
            Difficulty previous = Difficulty.EASY;
            for (Difficulty difficulty : schedule.getRoundDifficulties()) { if (difficulty.ordinal() < previous.ordinal()) invalid(); previous = difficulty; }
            Integer next = schedule.getMaxRatingExclusive();
            if (index == dto.getSchedules().size() - 1) { if (next != null) invalid(); }
            else { if (next == null || next <= floor) invalid(); floor = next; }
        }
    }
    private void invalid() { throw new BusinessValidationException("INVALID_DISCIPLINE_CONFIG", "Invalid discipline configuration."); }
}
