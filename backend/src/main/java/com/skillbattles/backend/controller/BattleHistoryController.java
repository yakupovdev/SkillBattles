package com.skillbattles.backend.controller;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.BusinessValidationException;
import com.skillbattles.backend.mapper.BattleHistoryMapper;
import com.skillbattles.backend.service.BattleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/v1/users/me/battles")
@RequiredArgsConstructor
@Tag(name = "Battle history")
@SecurityRequirement(name = "accessBearer")
public class BattleHistoryController {
    private final BattleService service;
    private final com.skillbattles.backend.processor.BattleAccessProcessor access;
    private final BattleHistoryMapper mapper;

    @GetMapping
    @Operation(operationId = "getUsersMeBattles", summary = "Get own terminal battle history", description = "Includes ranked, private and cancelled battles, using saved results and opponent snapshots. Does not advance the engine or apply ratings.")
    @ApiResponse(responseCode = "200", description = "History page; empty data is valid")
    @ApiResponse(responseCode = "400", description = "VALIDATION_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "401", description = "UNAUTHORIZED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "500", description = "INTERNAL_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public BattleHistoryPage history(@AuthenticationPrincipal Jwt jwt,
            @Parameter(schema = @Schema(minimum = "0")) @RequestParam(defaultValue = "0") int page,
            @Parameter(schema = @Schema(minimum = "1", maximum = "100")) @RequestParam(defaultValue = "20") int size,
            @Parameter(schema = @Schema(allowableValues = {"createdAt,asc", "createdAt,desc"})) @RequestParam(defaultValue = "createdAt,desc") String sort,
            @RequestParam(required = false) String disciplineCode, @RequestParam(required = false) BattleMode mode,
            HttpServletRequest request) {
        for (String name : List.of("page", "size", "sort", "disciplineCode", "mode")) {
            if (request.getParameterMap().containsKey(name) && request.getParameter(name).isBlank())
                throw new BusinessValidationException("VALIDATION_ERROR", "History query parameters cannot be blank.");
        }
        return access.history(new BattleHistoryQueryDto(UUID.fromString(jwt.getSubject()), page, size, sort, disciplineCode, mode));
    }
}
