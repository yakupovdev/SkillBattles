package com.skillbattles.backend.service;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.*;
import com.fasterxml.jackson.databind.cfg.CoercionAction;
import com.fasterxml.jackson.databind.cfg.CoercionInputShape;
import com.fasterxml.jackson.databind.type.LogicalType;
import com.skillbattles.backend.dto.QuestionImportDto;
import com.skillbattles.backend.exception.BusinessValidationException;
import org.springframework.stereotype.Service;
import java.io.IOException;
import java.nio.file.Path;
import java.util.List;

@Service
public class QuestionImportFileServiceImpl implements QuestionImportFileService {
    private final ObjectReader reader;

    public QuestionImportFileServiceImpl(ObjectMapper mapper) {
        ObjectMapper importMapper = mapper.copy();
        importMapper.setConfig(importMapper.getDeserializationConfig().without(MapperFeature.ALLOW_COERCION_OF_SCALARS));
        importMapper.coercionConfigFor(LogicalType.Textual)
                .setCoercion(CoercionInputShape.Integer, CoercionAction.Fail)
                .setCoercion(CoercionInputShape.Float, CoercionAction.Fail)
                .setCoercion(CoercionInputShape.Boolean, CoercionAction.Fail);
        this.reader = importMapper.enable(JsonParser.Feature.STRICT_DUPLICATE_DETECTION)
                .readerFor(new TypeReference<List<QuestionImportDto>>() {})
                .with(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, DeserializationFeature.FAIL_ON_NUMBERS_FOR_ENUMS,
                        DeserializationFeature.FAIL_ON_TRAILING_TOKENS)
                .without(DeserializationFeature.ACCEPT_FLOAT_AS_INT);
    }

    @Override
    public List<QuestionImportDto> read(Path path) {
        try { return reader.readValue(path.toFile()); }
        catch (IOException ex) {
            throw new BusinessValidationException("QUESTION_IMPORT_INVALID", "Cannot read question import file or invalid JSON schema.");
        }
    }
}
