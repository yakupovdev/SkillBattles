package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.exception.BusinessValidationException;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Component @RequiredArgsConstructor
public class QuestionImportProcessorImpl implements QuestionImportProcessor {
    private final QuestionService questions;
    private final DisciplineService disciplines;
    @Override @Transactional public QuestionImportResultDto importQuestions(List<QuestionImportDto> batch, boolean dryRun) {
        if (batch == null || batch.isEmpty()) throw invalid();
        Map<String, Map<String, String>> topics = new TreeMap<>();
        for (var item : batch) {
            if (item == null || item.getDisciplineCode() == null) throw invalid();
            if (!topics.containsKey(item.getDisciplineCode())) {
                try { disciplines.get(item.getDisciplineCode()); } catch (com.skillbattles.backend.exception.BusinessException ex) { throw invalid(); }
            }
            Map<String, String> names = topics.computeIfAbsent(item.getDisciplineCode(), ignored -> new TreeMap<>());
            if (item.getTopicCode() == null || item.getTopicName() == null) throw invalid();
            String previous = names.putIfAbsent(item.getTopicCode(), item.getTopicName());
            if (previous != null && !previous.equals(item.getTopicName())) throw invalid();
        }
        var result = questions.importQuestions(batch, dryRun);
        if (!dryRun) topics.forEach((code, names) -> disciplines.mergeTopics(code, names.entrySet().stream().map(e -> new TopicDto(e.getKey(), e.getValue())).toList()));
        return result;
    }
    private BusinessValidationException invalid() { return new BusinessValidationException("QUESTION_IMPORT_INVALID", "Unknown discipline or invalid/inconsistent topic metadata."); }
}
