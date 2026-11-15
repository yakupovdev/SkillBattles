package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class FriendProfileResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private PublicPlayer friend;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant friendsSince;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private List<FriendDisciplineStatistics> disciplines;
}
