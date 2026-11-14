package com.skillbattles.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillbattles.backend.exception.BusinessValidationException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import java.nio.file.*;
import java.util.List;
import static org.assertj.core.api.Assertions.*;

class QuestionImportFileServiceTest {
    @TempDir Path directory;
    private final QuestionImportFileService service = new QuestionImportFileServiceImpl(new ObjectMapper());
    private static final String VALID = """
            [{"externalKey":"test-only", "contentVersion":1, "subject":"MATH", "topic":"Test",
              "difficulty":"MEDIUM", "prompt":"TEST ONLY", "options":[], "correctOptionKey":"A", "explanation":"TEST ONLY"}]
            """;

    @Test
    void rejectsUnknownFieldsEnumsDuplicateJsonKeysAndNumericCoercion() throws Exception {
        List<String> invalid = List.of(
                VALID.replace("\"contentVersion\":1", "\"contentVersion\":1, \"extra\":true"),
                VALID.replace("\"MATH\"", "\"SCIENCE\""),
                VALID.replace("\"MATH\"", "0"),
                VALID.replace("\"contentVersion\":1", "\"contentVersion\":1, \"contentVersion\":2"),
                VALID.replace("\"contentVersion\":1", "\"contentVersion\":1.5"),
                VALID.replace("\"contentVersion\":1", "\"contentVersion\":\"1\""),
                VALID + " []");
        for (String content : invalid) {
            Path path = Files.writeString(directory.resolve("input.json"), content);
            assertThatThrownBy(() -> service.read(path)).isInstanceOf(BusinessValidationException.class);
        }
    }

    @Test
    void reportsMissingFilesWithoutExposingFileContents() {
        assertThatThrownBy(() -> service.read(directory.resolve("missing.json")))
                .isInstanceOf(BusinessValidationException.class).hasMessage("Cannot read question import file or invalid JSON schema.");
    }
}
