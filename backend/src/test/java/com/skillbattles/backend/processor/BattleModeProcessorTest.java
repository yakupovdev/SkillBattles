package com.skillbattles.backend.processor;

import com.skillbattles.backend.config.BattleProperties;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.service.*;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.util.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class BattleModeProcessorTest {
    @Test void availabilityIncludesMediumReserveAndUsesDataDefinedDiscipline() {
        var questions = mock(QuestionService.class); var disciplines = mock(DisciplineService.class);
        var ratings = mock(RatingService.class); var users = mock(UserService.class);
        var rollover = mock(RatingProcessor.class);
        var properties = new BattleProperties(); properties.setReadyTimeoutSeconds(30); properties.setCountdownSeconds(3); properties.setRevealSeconds(5);
        var discipline = new DisciplineDto("CUSTOM_SKILLS", "Custom skills", "Test only", true, BattleFormat.STANDARD, QuestionType.SINGLE_CHOICE, 4, 5, 60, 30,
                List.of(new DifficultyTimingDto(Difficulty.EASY, new BigDecimal("0.75"), 800), new DifficultyTimingDto(Difficulty.MEDIUM, BigDecimal.ONE, 1000), new DifficultyTimingDto(Difficulty.HARD, new BigDecimal("1.5"), 1200)),
                List.of(new DifficultyScheduleDto(0, null, List.of(Difficulty.EASY, Difficulty.EASY, Difficulty.MEDIUM, Difficulty.MEDIUM, Difficulty.HARD))), List.of());
        UUID userId = UUID.randomUUID(); var rating = new RatingDto(); rating.setDisciplineCode(discipline.getCode()); rating.setRating(1000);
        when(disciplines.active()).thenReturn(List.of(discipline)); when(rollover.prepare(userId)).thenReturn(List.of(rating));
        when(disciplines.limitSeconds(any(), any())).thenAnswer(call -> 45);
        when(questions.countAvailable("CUSTOM_SKILLS", Difficulty.EASY)).thenReturn(2L);
        when(questions.countAvailable("CUSTOM_SKILLS", Difficulty.MEDIUM)).thenReturn(2L);
        when(questions.countAvailable("CUSTOM_SKILLS", Difficulty.HARD)).thenReturn(1L);
        var processor = new BattleModeProcessorImpl(questions, properties, disciplines, ratings, users, rollover);
        assertThat(processor.getModes(userId).getFirst().isContentAvailable()).isFalse();
        when(questions.countAvailable("CUSTOM_SKILLS", Difficulty.MEDIUM)).thenReturn(3L);
        var result = processor.getModes(userId).getFirst();
        assertThat(result.isContentAvailable()).isTrue(); assertThat(result.getDisciplineCode()).isEqualTo("CUSTOM_SKILLS");
        assertThat(result.getDifficultyTimings().getFirst().getLimitSeconds()).isEqualTo(45);
    }
}
