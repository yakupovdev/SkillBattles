package com.skillbattles.backend.controller;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.mapper.MatchmakingMapper;
import com.skillbattles.backend.processor.MatchmakingProcessor;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/matchmaking/entries")
@RequiredArgsConstructor
@Tag(name = "Matchmaking")
@SecurityRequirement(name = "accessBearer")
@ApiResponse(responseCode = "400", description = "VALIDATION_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
@ApiResponse(responseCode = "401", description = "UNAUTHORIZED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
@ApiResponse(responseCode = "500", description = "INTERNAL_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
public class MatchmakingController {
    private final MatchmakingProcessor processor;
    private final MatchmakingMapper mapper;

    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "postMatchmakingEntries", summary = "Join ranked search", description = "Search the selected disciplineCode rating. A fast match may already return MATCHED and battleId.")
    @ApiResponse(responseCode = "201", description = "Search created")
    @ApiResponse(responseCode = "409", description = "ACTIVITY_CONFLICT or CONTENT_UNAVAILABLE", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "429", description = "DAILY_LIMIT_REACHED")
    public QueueEntryResponse search(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody DisciplineRequest request) {
        return mapper.toResponse(processor.search(UUID.fromString(jwt.getSubject()), request.getDisciplineCode()));
    }

    @GetMapping("/{id}")
    @Operation(operationId = "getMatchmakingEntriesId", summary = "Get owned search", description = "Includes terminal entries until restart. Missing or foreign entries return 404.")
    @ApiResponse(responseCode = "200", description = "Current search snapshot")
    @ApiResponse(responseCode = "404", description = "QUEUE_ENTRY_NOT_FOUND", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public QueueEntryResponse entry(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        return mapper.toResponse(processor.entry(UUID.fromString(jwt.getSubject()), id));
    }

    @DeleteMapping("/{id}") @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "deleteMatchmakingEntriesId", summary = "Cancel owned search", description = "Idempotent for cancelled/expired entries. If matching won, recover activity and open battle.")
    @ApiResponse(responseCode = "204", description = "Cancelled; empty body")
    @ApiResponse(responseCode = "404", description = "QUEUE_ENTRY_NOT_FOUND", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "409", description = "MATCH_ALREADY_FOUND", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public void cancel(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) { processor.cancelEntry(UUID.fromString(jwt.getSubject()), id); }
}
