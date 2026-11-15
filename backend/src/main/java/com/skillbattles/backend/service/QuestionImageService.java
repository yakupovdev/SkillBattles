package com.skillbattles.backend.service;

public interface QuestionImageService {
    String KEY_PATTERN = "[A-Z][A-Z0-9_]{1,63}/[a-f0-9]{8}/[a-f0-9]{64}\\.png";

    boolean isPackagedForQuestion(String key, String externalKey, String disciplineCode);
}
