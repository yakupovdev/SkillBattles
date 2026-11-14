package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RevealViewDto {
    private UUID correctOptionId;
    private List<AnswerViewDto> answers;
    private AnswerAccessDto answerAccess;
}
