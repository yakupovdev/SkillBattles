package com.skillbattles.backend.controller;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.mapper.BattleModeMapper;
import com.skillbattles.backend.processor.BattleModeProcessor;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/battle-modes")
@RequiredArgsConstructor
@Tag(name = "Battle modes")
public class BattleModeController {
    private final BattleModeProcessor processor;
    private final BattleModeMapper mapper;

    @GetMapping
    @Operation(summary = "Get discipline timings and content availability", description = "Returns all active disciplines from the catalogue. An empty or insufficient bank reports contentAvailable=false. Does not expose questions or answers.", security = @SecurityRequirement(name = "accessBearer"))
    @ApiResponse(responseCode = "200", description = "Current discipline configurations")
    @ApiResponse(responseCode = "401", description = "UNAUTHORIZED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "500", description = "INTERNAL_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public List<BattleModeResponse> modes(@org.springframework.security.core.annotation.AuthenticationPrincipal org.springframework.security.oauth2.jwt.Jwt jwt) {
        return processor.getModes(java.util.UUID.fromString(jwt.getSubject())).stream().map(mapper::toResponse).toList();
    }
}
