package com.skillbattles.backend.processor;

import com.skillbattles.backend.config.BattleProperties;
import com.skillbattles.backend.dto.BattleModeDto;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.service.QuestionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Component
@RequiredArgsConstructor
public class BattleModeProcessorImpl implements BattleModeProcessor {
    private final QuestionService questionService;
    private final BattleProperties properties;

    @Override
    @Transactional(readOnly = true)
    public List<BattleModeDto> getModes() {
        return Arrays.stream(Subject.values()).map(subject -> {
            var settings = properties.forSubject(subject);
            return new BattleModeDto(subject, settings.getQuestionCount(), settings.getQuestionLimitSeconds(),
                    properties.getReadyTimeoutSeconds(), properties.getCountdownSeconds(), properties.getRevealSeconds(),
                    questionService.countAvailable(subject, Difficulty.MEDIUM) >= settings.getQuestionCount());
        }).toList();
    }
}
