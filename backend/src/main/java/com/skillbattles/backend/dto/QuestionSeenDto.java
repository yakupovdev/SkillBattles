package com.skillbattles.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.time.Instant;
import java.util.UUID;

@Getter
@AllArgsConstructor
public class QuestionSeenDto {
    private final UUID questionId;
    private final Instant shownAt;
}
