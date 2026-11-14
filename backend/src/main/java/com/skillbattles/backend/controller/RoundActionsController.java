package com.skillbattles.backend.controller;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.processor.RoundActionsProcessor;
import com.skillbattles.backend.mapper.ReportMapper;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import java.util.UUID;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.responses.ApiResponse;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
@SecurityRequirement(name="accessBearer")
@ApiResponse(responseCode="400", description="VALIDATION_ERROR")
@ApiResponse(responseCode="401", description="UNAUTHORIZED")
@ApiResponse(responseCode="403", description="HISTORY_ACCESS_REQUIRED")
@ApiResponse(responseCode="404", description="BATTLE_NOT_FOUND or ROUND_NOT_FOUND")
public class RoundActionsController {
    private final RoundActionsProcessor processor;
    private final ReportMapper reports;

    @PostMapping("/battles/{id}/rounds/{roundId}/report")
    @Operation(summary="Report a shown round", description="Exact repeat returns the original report with 200; conflicting payload returns 409.")
    @ApiResponse(responseCode="201", description="Report received")
    @ApiResponse(responseCode="200", description="Identical report already received")
    @ApiResponse(responseCode="409", description="ROUND_NOT_REVEALED or REPORT_ALREADY_EXISTS")
    public ResponseEntity<ReportResponse> report(@PathVariable UUID id, @PathVariable UUID roundId,
            @AuthenticationPrincipal Jwt jwt, @Valid @RequestBody ReportRequest request) {
        var dto = processor.report(id, roundId, UUID.fromString(jwt.getSubject()), request.getReason(), request.getComment());
        return ResponseEntity.status(dto.isCreated() ? 201 : 200).body(reports.toResponse(dto));
    }
}
