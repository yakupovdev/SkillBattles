package com.skillbattles.backend.processor;

import com.skillbattles.backend.config.BattleProperties;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.service.QuestionService;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class BattleModeProcessorTest {
    @Test
    void availabilityUsesConfiguredCountForEachSubject() {
        QuestionService questions = mock(QuestionService.class);
        BattleProperties properties = new BattleProperties();
        var math = new BattleProperties.SubjectSettings();
        math.setQuestionCount(5);
        math.setQuestionLimitSeconds(42);
        var english = new BattleProperties.SubjectSettings();
        english.setQuestionCount(2);
        english.setQuestionLimitSeconds(60);
        properties.setMath(math);
        properties.setEnglish(english);
        properties.setReadyTimeoutSeconds(20);
        properties.setCountdownSeconds(2);
        properties.setRevealSeconds(4);
        when(questions.countAvailable(Subject.MATH, Difficulty.MEDIUM)).thenReturn(4L);
        when(questions.countAvailable(Subject.ENGLISH, Difficulty.MEDIUM)).thenReturn(2L);
        var modes = new BattleModeProcessorImpl(questions, properties).getModes();
        assertThat(modes.getFirst().isContentAvailable()).isFalse();
        assertThat(modes.getFirst().getQuestionCount()).isEqualTo(5);
        assertThat(modes.getFirst().getQuestionLimitSeconds()).isEqualTo(42);
        assertThat(modes.getFirst().getReadyTimeoutSeconds()).isEqualTo(20);
        assertThat(modes.get(1).isContentAvailable()).isTrue();
    }
}
