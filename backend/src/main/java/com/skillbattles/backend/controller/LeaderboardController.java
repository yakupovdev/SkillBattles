package com.skillbattles.backend.controller;
import com.skillbattles.backend.dto.*;import com.skillbattles.backend.processor.LeaderboardProcessor;
import org.springframework.web.bind.annotation.*;import org.springframework.security.core.annotation.AuthenticationPrincipal;import org.springframework.security.oauth2.jwt.Jwt;
import lombok.RequiredArgsConstructor;import java.util.UUID;import io.swagger.v3.oas.annotations.Operation;import io.swagger.v3.oas.annotations.security.SecurityRequirement;import io.swagger.v3.oas.annotations.responses.ApiResponse;
@RestController @RequestMapping("/api/v1/leaderboards") @RequiredArgsConstructor @SecurityRequirement(name="accessBearer")
public class LeaderboardController {
 private final LeaderboardProcessor processor;
 @GetMapping("/{disciplineCode}") @Operation(summary="Get current season top 50 and own position",description="Rating descending, rating reached time ascending, user UUID ascending; calibration included, rollover pending excluded.")
 @ApiResponse(responseCode="200",description="Leaderboard") @ApiResponse(responseCode="404",description="DISCIPLINE_NOT_FOUND")
 public LeaderboardResponse get(@PathVariable String disciplineCode,@AuthenticationPrincipal Jwt jwt){return processor.get(disciplineCode,UUID.fromString(jwt.getSubject()));}
}
