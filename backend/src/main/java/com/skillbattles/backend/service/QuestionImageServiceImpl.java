package com.skillbattles.backend.service;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;
import java.util.regex.Pattern;

@Service
public class QuestionImageServiceImpl implements QuestionImageService {
    private static final Pattern KEY = Pattern.compile(KEY_PATTERN);

    @Override
    public boolean isPackagedForQuestion(String key, String externalKey, String disciplineCode) {
        if (key == null || !KEY.matcher(key).matches()) return false;
        String[] parts = key.split("/");
        return parts[0].equals(disciplineCode) && (parts[0] + ":" + parts[1]).equals(externalKey)
                && new ClassPathResource("question-images/" + key).isReadable();
    }
}
