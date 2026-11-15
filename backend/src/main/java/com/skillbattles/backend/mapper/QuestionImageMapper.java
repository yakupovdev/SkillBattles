package com.skillbattles.backend.mapper;

import org.mapstruct.Named;

public final class QuestionImageMapper {
    private QuestionImageMapper() { }

    @Named("questionImageUrl")
    public static String imageUrl(String imageKey) {
        return imageKey == null ? null : "/media/questions/" + imageKey;
    }
}
