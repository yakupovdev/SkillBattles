package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class SendDuelInvitationRequest {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull
    private UUID friendId;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull
    private UUID requestId;
}
