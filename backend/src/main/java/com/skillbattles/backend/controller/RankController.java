package com.skillbattles.backend.controller;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.mapper.RankMapper;
import com.skillbattles.backend.service.RankService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController @RequestMapping("/api/v1/ranks") @RequiredArgsConstructor
@SecurityRequirement(name = "accessBearer")
public class RankController {
    private final RankService service;
    private final RankMapper mapper;
    @GetMapping @Operation(summary = "Get all 27 ordered rank thresholds")
    @ApiResponse(responseCode = "200", description = "Rank catalogue, including the unbounded Legend tier")
    @ApiResponse(responseCode = "401", description = "UNAUTHORIZED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "500", description = "INTERNAL_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public List<RankTier> ranks() { return service.tiers().stream().map(mapper::toResponse).toList(); }
}
