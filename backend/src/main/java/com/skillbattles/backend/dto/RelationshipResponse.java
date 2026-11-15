package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class RelationshipResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private UUID id;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private PublicPlayer requester;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private PublicPlayer recipient;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private FriendStatus status;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant createdAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private Instant updatedAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, nullable = true)
    private Instant acceptedAt;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, minimum = "1")
    private int version;
}
