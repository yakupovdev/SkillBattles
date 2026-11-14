package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class ReviewRoundDto {
    private UUID roundId;
    private int number;
    @com.fasterxml.jackson.annotation.JsonProperty("isOvertimeRound")
    private boolean overtimeRound;
    private boolean completed;
    private ReviewQuestionDto question;
    private List<AnswerViewDto> answers;
}
