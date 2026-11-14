package com.skillbattles.backend.controller;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.mapper.MatchmakingMapper;
import com.skillbattles.backend.processor.MatchmakingProcessor;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users/me/activity")
@RequiredArgsConstructor
@Tag(name = "Users")
@SecurityRequirement(name = "accessBearer")
public class ActivityController {
    private final MatchmakingProcessor processor;
    private final MatchmakingMapper mapper;
    @GetMapping
    @Operation(operationId = "getUsersMeActivity", summary = "Recover the current account activity", description = "Returns NONE, QUEUE, PRIVATE_DUEL or BATTLE. Subscribe first, then fetch activity and its REST snapshot; merge events by resourceId/version.")
    @ApiResponse(responseCode = "200", description = "Current activity; nullable IDs are explicit null")
    @ApiResponse(responseCode = "400", description = "VALIDATION_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "401", description = "UNAUTHORIZED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "500", description = "INTERNAL_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public ActivityResponse activity(@AuthenticationPrincipal Jwt jwt) { return mapper.toResponse(processor.activity(UUID.fromString(jwt.getSubject()))); }
}
