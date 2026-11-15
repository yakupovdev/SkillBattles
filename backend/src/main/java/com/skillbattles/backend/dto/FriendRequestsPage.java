package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class FriendRequestsPage {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private List<RelationshipResponse> data;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private PaginationDto pagination;
}
