package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import org.mapstruct.*;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

@Mapper(config = CommonMapperConfig.class)
public interface QuestionMapper {
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "deleted", ignore = true)
    @Mapping(target = "active", ignore = true)
    @Mapping(target = "options", ignore = true)
    @Mapping(target = "correctOptionId", ignore = true)
    Question toEntity(QuestionImportDto dto);

    @Mapping(target = "correctOptionKey", expression = "java(question.getOptions().stream().filter(option -> option.getId().equals(question.getCorrectOptionId())).findFirst().orElseThrow().getKey())")
    QuestionImportDto toImportDto(Question question);

    @AfterMapping
    default void setOptions(QuestionImportDto dto, @MappingTarget Question question) {
        question.setOptions(dto.getOptions().stream().map(option -> new QuestionOption(
                optionId(dto, option.getKey()), option.getKey(), option.getText())).toList());
        question.setCorrectOptionId(optionId(dto, dto.getCorrectOptionKey()));
    }

    default UUID optionId(QuestionImportDto dto, String key) {
        return UUID.nameUUIDFromBytes(("skillbattles:question:" + dto.getExternalKey().length() + ":"
                + dto.getExternalKey() + ":" + dto.getContentVersion() + ":" + key).getBytes(StandardCharsets.UTF_8));
    }
}
