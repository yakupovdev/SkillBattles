package com.skillbattles.backend.controller;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.service.*;
import com.skillbattles.backend.processor.SeasonProcessor;
import com.skillbattles.backend.mapper.SeasonMapper;
import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import java.util.UUID;
@RestController @RequestMapping("/api/v1") @RequiredArgsConstructor
@SecurityRequirement(name="accessBearer")
@ApiResponse(responseCode="401",description="UNAUTHORIZED",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
@ApiResponse(responseCode="500",description="INTERNAL_ERROR",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
public class SeasonController {
    private final SeasonService seasons;
    private final SeasonMapper mapper;
    private final SeasonProcessor processor;
    @GetMapping("/seasons/current") @Operation(operationId="getSeasonsCurrent",summary="Get current calendar season in America/New_York")
    @ApiResponse(responseCode="200",description="Global current season, independent of pending settlements")
    public SeasonResponse current() {return mapper.toResponse(seasons.current());}
    @GetMapping("/users/me/seasons") @Operation(operationId="getUsersMeSeasons",summary="Get own completed season ratings and peaks")
    @ApiResponse(responseCode="200",description="Completed seasons ordered newest first, then discipline code")
    @ApiResponse(responseCode="400",description="VALIDATION_ERROR",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public SeasonHistoryPage history(@AuthenticationPrincipal Jwt jwt,@RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="20") int size,@RequestParam(required=false) String disciplineCode) {
        UUID userId=UUID.fromString(jwt.getSubject());
        var history=processor.history(userId,disciplineCode,page,size);
        return new SeasonHistoryPage(history.getData().stream().map(mapper::toResponse).toList(),history.getPagination());
    }
}
