package com.skillbattles.backend.controller;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.handler.BattleRequestTimeFilter;
import com.skillbattles.backend.mapper.BattleSnapshotMapper;
import com.skillbattles.backend.mapper.BattleReviewMapper;
import com.skillbattles.backend.processor.BattleProcessor;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/battles")
@RequiredArgsConstructor
@Tag(name = "Battles")
@SecurityRequirement(name = "accessBearer")
@ApiResponse(responseCode = "400", description = "VALIDATION_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
@ApiResponse(responseCode = "401", description = "UNAUTHORIZED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
@ApiResponse(responseCode = "404", description = "BATTLE_NOT_FOUND: missing or not a participant", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
@ApiResponse(responseCode = "500", description = "INTERNAL_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
public class BattleController {
    private final BattleProcessor processor;
    private final BattleSnapshotMapper mapper;
    private final BattleReviewMapper reviewMapper;

    @GetMapping("/{id}")
    @Operation(summary = "Get participant-specific battle state", description = "Shows only the current question. Opponent selection and current-round correctness and points are hidden until reveal.")
    @ApiResponse(responseCode = "200", description = "Authoritative redacted snapshot")
    public BattleSnapshot snapshot(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        return mapper.toResponse(processor.snapshot(id, UUID.fromString(jwt.getSubject())));
    }

    @PostMapping("/{id}/readiness")
    @Operation(summary = "Set ready=true", description = "Requires an authenticated live realtime subscription. Idempotent while WAITING_READY; both ready and online starts COUNTDOWN.")
    @ApiResponse(responseCode = "200", description = "Updated battle snapshot")
    @ApiResponse(responseCode = "409", description = "INVALID_BATTLE_STATE or REALTIME_CONNECTION_REQUIRED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public BattleSnapshot ready(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt, @Valid @RequestBody ReadinessRequest request) {
        return mapper.toResponse(processor.ready(id, UUID.fromString(jwt.getSubject())));
    }

    @PostMapping("/{id}/answers")
    @Operation(summary = "Submit one final option for a round", description = "Server entry time is authoritative. An identical submission retry returns the original receipt, including after the round closes. Receipt never reveals correctness or points.")
    @ApiResponse(responseCode = "200", description = "Answer accepted")
    @ApiResponse(responseCode = "400", description = "VALIDATION_ERROR or INVALID_OPTION", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "409", description = "IDEMPOTENCY_CONFLICT, ANSWER_ALREADY_SUBMITTED, ROUND_CLOSED or INVALID_BATTLE_STATE", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public AnswerReceipt answer(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody AnswerRequest request, HttpServletRequest servletRequest) {
        Instant receivedAt = (Instant) servletRequest.getAttribute(BattleRequestTimeFilter.RECEIVED_AT);
        return mapper.toResponse(processor.answer(id, UUID.fromString(jwt.getSubject()), mapper.toDto(request), receivedAt));
    }

    @PostMapping("/{id}/surrender")
    @Operation(summary = "Surrender a battle", description = "Before the first question: cancel without rating. After start: forfeit. Terminal state is immutable on repeated requests.")
    @ApiResponse(responseCode = "200", description = "Current battle snapshot")
    public BattleSnapshot surrender(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        return mapper.toResponse(processor.surrender(id, UUID.fromString(jwt.getSubject())));
    }

    @GetMapping("/{id}/result")
    @Operation(summary = "Get the final result relative to the caller", description = "Returns final score and actual rating deltas. Private and cancelled battles never change ratings.")
    @ApiResponse(responseCode = "200", description = "Final result")
    @ApiResponse(responseCode = "409", description = "BATTLE_NOT_FINISHED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public BattleResultResponse result(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        return mapper.toResponse(processor.result(id, UUID.fromString(jwt.getSubject())));
    }

    @GetMapping("/{id}/review")
    @Operation(operationId = "getBattlesIdReview", summary = "Review own terminal battle", description = "Started rounds only, using immutable saved question and answer snapshots. Incomplete rounds include only accepted answers; learning breakdown never changes final scores.")
    @ApiResponse(responseCode = "200", description = "Started-round review")
    @ApiResponse(responseCode = "409", description = "BATTLE_NOT_FINISHED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public BattleReview review(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        return reviewMapper.toResponse(processor.review(id, UUID.fromString(jwt.getSubject())));
    }
}
