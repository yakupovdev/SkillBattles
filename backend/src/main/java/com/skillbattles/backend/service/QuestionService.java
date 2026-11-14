package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import java.util.List;

public interface QuestionService {
    QuestionImportResultDto importQuestions(List<QuestionImportDto> questions, boolean dryRun);
    long countAvailable(Subject subject, Difficulty difficulty);
    List<FrozenQuestionDto> selectForBattle(QuestionSelectionDto selection);
}
