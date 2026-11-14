package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.mapper.QuestionMapper;
import com.skillbattles.backend.repository.QuestionRepository;
import jakarta.validation.Validator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class QuestionServiceImpl implements QuestionService {
    private final QuestionRepository repository;
    private final QuestionMapper mapper;
    private final Validator validator;
    private final Clock clock;

    @Override
    @Transactional
    public QuestionImportResultDto importQuestions(List<QuestionImportDto> questions, boolean dryRun) {
        validate(questions);
        repository.lockImport();
        Set<String> keys = questions.stream().map(QuestionImportDto::getExternalKey).collect(Collectors.toSet());
        List<Question> existing = repository.findAllByExternalKeyIn(keys);
        Map<Revision, Question> revisions = existing.stream().collect(Collectors.toMap(
                question -> new Revision(question.getExternalKey(), question.getContentVersion()), question -> question));
        Map<String, Integer> storedVersions = new HashMap<>();
        existing.forEach(question -> storedVersions.merge(question.getExternalKey(), question.getContentVersion(), Math::max));
        Map<String, Integer> importedVersions = new HashMap<>();
        List<QuestionImportDto> additions = new ArrayList<>();

        // Check the entire batch and existing content before making any changes.
        for (QuestionImportDto dto : questions) {
            importedVersions.merge(dto.getExternalKey(), dto.getContentVersion(), Math::max);
            Question stored = revisions.get(new Revision(dto.getExternalKey(), dto.getContentVersion()));
            if (stored == null) additions.add(dto);
            else if (!dto.equals(mapper.toImportDto(stored))) {
                throw new ConflictException("QUESTION_REVISION_CONFLICT", "An existing question revision has different content. Use a new contentVersion.");
            }
        }
        if (!dryRun && !additions.isEmpty()) {
            List<String> supersededKeys = importedVersions.entrySet().stream()
                    .filter(entry -> entry.getValue() > storedVersions.getOrDefault(entry.getKey(), 0))
                    .map(Map.Entry::getKey).toList();
            if (!supersededKeys.isEmpty()) {
                repository.deactivate(supersededKeys, LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC));
            }
            List<Question> entities = additions.stream().map(dto -> {
                Question question = mapper.toEntity(dto);
                question.setActive(dto.getContentVersion().equals(importedVersions.get(dto.getExternalKey()))
                        && dto.getContentVersion() > storedVersions.getOrDefault(dto.getExternalKey(), 0));
                return question;
            }).toList();
            repository.saveAll(entities);
            repository.flush();
        }
        return new QuestionImportResultDto(dryRun, questions.size(), additions.size(), questions.size() - additions.size());
    }

    @Override
    public long countAvailable(Subject subject, Difficulty difficulty) {
        return repository.countBySubjectAndDifficultyAndActiveTrue(subject, difficulty);
    }

    private void validate(List<QuestionImportDto> questions) {
        if (questions == null || questions.isEmpty()) invalid("Import must be a nonempty JSON array.");
        Set<Revision> revisions = new HashSet<>();
        for (int i = 0; i < questions.size(); i++) {
            QuestionImportDto dto = questions.get(i);
            if (dto == null) invalid("Question at index " + i + " must not be null.");
            var violations = validator.validate(dto);
            if (!violations.isEmpty()) {
                String fields = violations.stream().map(violation -> violation.getPropertyPath().toString()).distinct().sorted().collect(Collectors.joining(", "));
                invalid("Invalid fields at question index " + i + ": " + fields + ".");
            }
            Set<String> optionKeys = dto.getOptions().stream().map(QuestionOptionImportDto::getKey).collect(Collectors.toSet());
            if (optionKeys.size() != 4 || !optionKeys.contains(dto.getCorrectOptionKey())) {
                invalid("Question at index " + i + " must have four distinct option keys and a matching correctOptionKey.");
            }
            if (!revisions.add(new Revision(dto.getExternalKey(), dto.getContentVersion()))) {
                invalid("Duplicate externalKey/contentVersion pair at question index " + i + ".");
            }
        }
    }

    private void invalid(String message) { throw new BusinessValidationException("QUESTION_IMPORT_INVALID", message); }
    private record Revision(String key, int version) { }
}
