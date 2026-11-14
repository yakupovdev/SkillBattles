package com.skillbattles.backend.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import java.util.UUID;

@Getter
@Setter
public class AnswerRequest {
    @NotNull(message = "Round ID is required.")
    private UUID roundId;
    @NotNull(message = "Option ID is required.")
    private UUID optionId;
    @NotNull(message = "Submission ID is required.")
    private UUID submissionId;
}
