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
@RequestMapping("/api/v1/duels")
@RequiredArgsConstructor
@Tag(name = "Private duels")
@SecurityRequirement(name = "accessBearer")
@ApiResponse(responseCode = "400", description = "VALIDATION_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
@ApiResponse(responseCode = "401", description = "UNAUTHORIZED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
@ApiResponse(responseCode = "500", description = "INTERNAL_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
public class DuelController {
    private final MatchmakingProcessor processor;
    private final MatchmakingMapper mapper;

    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    @Operation(operationId = "postDuels", summary = "Create a waiting private duel", description = "Share the six-character code. The room expires in ten minutes.")
    @ApiResponse(responseCode = "201", description = "Waiting duel created")
    @ApiResponse(responseCode = "409", description = "ACTIVITY_CONFLICT or CONTENT_UNAVAILABLE", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public DuelResponse create(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody SubjectRequest request) {
        return mapper.toResponse(processor.createDuel(UUID.fromString(jwt.getSubject()), request.getSubject()));
    }

    @PostMapping("/join")
    @Operation(operationId = "postDuelsJoin", summary = "Join a private code once", description = "Atomically assigns the guest and creates a PRIVATE battle. Repeat joins never create another battle.")
    @ApiResponse(responseCode = "200", description = "Matched duel with battleId")
    @ApiResponse(responseCode = "404", description = "DUEL_NOT_FOUND", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "409", description = "SELF_JOIN_NOT_ALLOWED, DUEL_NOT_JOINABLE, ACTIVITY_CONFLICT or CONTENT_UNAVAILABLE", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "410", description = "DUEL_EXPIRED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public DuelResponse join(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody JoinDuelRequest request) {
        return mapper.toResponse(processor.join(UUID.fromString(jwt.getSubject()), request.getCode()));
    }

    @GetMapping("/{id}")
    @Operation(operationId = "getDuelsId", summary = "Get a private duel", description = "Host or assigned guest only; other users see DUEL_NOT_FOUND.")
    @ApiResponse(responseCode = "200", description = "Current duel snapshot")
    @ApiResponse(responseCode = "404", description = "DUEL_NOT_FOUND", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public DuelResponse duel(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) { return mapper.toResponse(processor.duel(UUID.fromString(jwt.getSubject()), id)); }

    @DeleteMapping("/{id}") @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId = "deleteDuelsId", summary = "Cancel a waiting private duel", description = "Host only. Repeat cancellation/expiry is idempotent; a matched duel must be surrendered as a battle.")
    @ApiResponse(responseCode = "204", description = "Cancelled; empty body")
    @ApiResponse(responseCode = "404", description = "DUEL_NOT_FOUND", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "409", description = "MATCH_ALREADY_FOUND", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public void cancel(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) { processor.cancelDuel(UUID.fromString(jwt.getSubject()), id); }
}
