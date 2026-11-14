package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.QuestionImportDto;
import java.nio.file.Path;
import java.util.List;

public interface QuestionImportFileService {
    List<QuestionImportDto> read(Path path);
}
