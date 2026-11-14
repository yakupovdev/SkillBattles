package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;
import java.util.List;

public interface QuestionImportProcessor { QuestionImportResultDto importQuestions(List<QuestionImportDto> batch, boolean dryRun); }
