package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.Subject;
import lombok.AllArgsConstructor;
import lombok.Getter;
import java.util.List;

@Getter
@AllArgsConstructor
public class QuestionSelectionDto {
    private final Subject subject;
    private final int count;
    private final List<QuestionSeenDto> recentlySeen;
}
