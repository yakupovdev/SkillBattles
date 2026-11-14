package com.skillbattles.backend.controller;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.mapper.StatisticsMapper;
import com.skillbattles.backend.processor.StatisticsProcessor;
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
@RequestMapping("/api/v1/users/me/statistics")
@RequiredArgsConstructor
@Tag(name = "Users")
public class StatisticsController {
    private final StatisticsProcessor processor;
    private final StatisticsMapper mapper;

    @GetMapping
    @Operation(summary = "Get current user statistics by subject", description = "Separate subject ratings and ranks with ranked/private counts. Counts are zero until battle results are implemented; cancelled matches never contribute.", security = @SecurityRequirement(name = "accessBearer"))
    @ApiResponse(responseCode = "200", description = "Statistics for both subjects")
    @ApiResponse(responseCode = "401", description = "UNAUTHORIZED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "404", description = "USER_NOT_FOUND: account was deleted", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "500", description = "INTERNAL_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public StatisticsResponse statistics(@AuthenticationPrincipal Jwt jwt) {
        return mapper.toResponse(processor.getForUser(UUID.fromString(jwt.getSubject())));
    }
}
