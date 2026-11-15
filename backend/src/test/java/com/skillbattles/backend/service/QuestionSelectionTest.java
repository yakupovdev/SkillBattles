package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.mapper.QuestionMapper;
import com.skillbattles.backend.repository.*;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;
import org.mapstruct.factory.Mappers;
import java.time.*;
import java.util.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class QuestionSelectionTest {
    private final QuestionRepository repository = mock(QuestionRepository.class);
    private final QuestionService service = new QuestionServiceImpl(repository, Mappers.getMapper(QuestionMapper.class),
            mock(Validator.class), Clock.systemUTC(), new QuestionImageServiceImpl());
    private final Instant recent = Instant.parse("2026-11-14T12:00:00Z");

    @Test
    void equalRecencyPreservesRandomDatabaseOrderAndFreshQuestionsComeFirst() {
        Question a = question("a"), b = question("b"), fresh = question("fresh");
        var shows = List.of(new QuestionSeenDto(a.getId(), recent), new QuestionSeenDto(b.getId(), recent));
        when(repository.historicalIdentities(anyCollection())).thenReturn(List.of(identity(a), identity(b)));
        when(repository.selectUnseenForBattle(eq("SAT_MATH"), eq(2), anyCollection(), eq("MEDIUM"))).thenReturn(List.of(fresh));
        when(repository.selectSeenForBattle(eq("SAT_MATH"), anyCollection(), eq("MEDIUM"))).thenReturn(List.of(b, a));
        assertThat(service.selectForBattle(new QuestionSelectionDto("SAT_MATH", 2, shows)))
                .extracting(FrozenQuestionDto::getId).containsExactly(fresh.getId(), b.getId());
        when(repository.selectSeenForBattle(eq("SAT_MATH"), anyCollection(), eq("MEDIUM"))).thenReturn(List.of(a, b));
        assertThat(service.selectForBattle(new QuestionSelectionDto("SAT_MATH", 2, shows)))
                .extracting(FrozenQuestionDto::getId).containsExactly(fresh.getId(), a.getId());
    }

    @Test
    void latestShowAcrossDifferentRevisionsControlsFallback() {
        Question oldA = question("a"), newA = question("a"), b = question("b");
        var shows = List.of(new QuestionSeenDto(oldA.getId(), recent.minusSeconds(30)),
                new QuestionSeenDto(newA.getId(), recent), new QuestionSeenDto(b.getId(), recent.minusSeconds(10)));
        when(repository.historicalIdentities(anyCollection())).thenReturn(List.of(identity(oldA), identity(newA), identity(b)));
        when(repository.selectUnseenForBattle(eq("SAT_MATH"), eq(2), anyCollection(), eq("MEDIUM"))).thenReturn(List.of());
        when(repository.selectSeenForBattle(eq("SAT_MATH"), anyCollection(), eq("MEDIUM"))).thenReturn(List.of(newA, b));
        assertThat(service.selectForBattle(new QuestionSelectionDto("SAT_MATH", 2, shows)))
                .extracting(FrozenQuestionDto::getId).containsExactly(b.getId(), newA.getId());
    }

    @Test
    void sufficientFreshPoolNeverUsesFallback() {
        Question seen = question("seen"), first = question("fresh-1"), second = question("fresh-2");
        when(repository.historicalIdentities(anyCollection())).thenReturn(List.of(identity(seen)));
        when(repository.selectUnseenForBattle(eq("SAT_MATH"), eq(2), anyCollection(), eq("MEDIUM"))).thenReturn(List.of(first, second));
        assertThat(service.selectForBattle(new QuestionSelectionDto("SAT_MATH", 2,
                List.of(new QuestionSeenDto(seen.getId(), recent)))))
                .extracting(FrozenQuestionDto::getId).containsExactly(first.getId(), second.getId());
        verify(repository, never()).selectSeenForBattle(anyString(), anyCollection(), anyString());
    }

    private Question question(String key) {
        Question question = new Question();
        question.setId(UUID.randomUUID());
        question.setExternalKey(key);
        question.setDisciplineCode("SAT_MATH");
        question.setOptions(List.of());
        return question;
    }

    private QuestionIdentityProjection identity(Question question) {
        return new QuestionIdentityProjection() {
            @Override public UUID getId() { return question.getId(); }
            @Override public String getExternalKey() { return question.getExternalKey(); }
        };
    }
}
