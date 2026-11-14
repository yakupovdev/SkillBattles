package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AnswerReceiptDto {
    private UUID battleId;
    private UUID roundId;
    private UUID submissionId;
    private boolean accepted;
    private Instant acceptedAt;
}

