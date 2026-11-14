package com.skillbattles.backend.config;

import com.skillbattles.backend.service.*;
import com.skillbattles.backend.processor.QuestionImportProcessor;
import com.skillbattles.backend.exception.BusinessValidationException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import java.nio.file.Path;
import java.util.List;

@Slf4j
@Component
@Profile("question-import")
@RequiredArgsConstructor
public class QuestionImportRunner implements ApplicationRunner {
    private final QuestionImportFileService files;
    private final QuestionImportProcessor questions;

    @Override
    public void run(ApplicationArguments args) {
        List<String> paths = args.getOptionValues("questions.file");
        if (paths == null || paths.size() != 1 || paths.getFirst().isBlank()) {
            throw new BusinessValidationException("QUESTION_IMPORT_INVALID", "Supply exactly one --questions.file=/absolute/path/questions.json.");
        }
        List<String> apply = args.getOptionValues("questions.apply");
        if (args.containsOption("questions.apply") && (apply == null || apply.size() != 1 || !List.of("true", "false").contains(apply.getFirst()))) {
            throw new BusinessValidationException("QUESTION_IMPORT_INVALID", "Use --questions.apply=true or --questions.apply=false.");
        }
        boolean dryRun = apply == null || !Boolean.parseBoolean(apply.getFirst());
        var result = questions.importQuestions(files.read(Path.of(paths.getFirst())), dryRun);
        log.info("Question import: dryRun={}, validated={}, inserted={}, unchanged={}", result.isDryRun(), result.getValidated(), result.getInserted(), result.getUnchanged());
    }
}
