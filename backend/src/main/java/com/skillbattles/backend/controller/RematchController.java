package com.skillbattles.backend.controller;
import com.skillbattles.backend.dto.*;import com.skillbattles.backend.processor.RematchProcessor;import com.skillbattles.backend.mapper.MatchmakingMapper;
import org.springframework.web.bind.annotation.*;import org.springframework.http.HttpStatus;import org.springframework.security.core.annotation.AuthenticationPrincipal;import org.springframework.security.oauth2.jwt.Jwt;import lombok.RequiredArgsConstructor;import java.util.UUID;
import io.swagger.v3.oas.annotations.Operation;import io.swagger.v3.oas.annotations.security.SecurityRequirement;import io.swagger.v3.oas.annotations.responses.ApiResponse;
@RestController @RequestMapping("/api/v1/battles/{id}/rematch") @RequiredArgsConstructor @SecurityRequirement(name="accessBearer")
@ApiResponse(responseCode="401",description="UNAUTHORIZED") @ApiResponse(responseCode="403",description="HISTORY_ACCESS_REQUIRED") @ApiResponse(responseCode="404",description="BATTLE_NOT_FOUND or REMATCH_NOT_FOUND") @ApiResponse(responseCode="409",description="REMATCH_NOT_ALLOWED, ACTIVITY_CONFLICT, CONTENT_UNAVAILABLE or MATCH_ALREADY_FOUND")
public class RematchController {
 private final RematchProcessor processor;private final MatchmakingMapper mapper;
 @PostMapping @Operation(summary="Consent to a private rematch",description="First consent reserves requester activity for 60 seconds. Second consent atomically creates one new private battle requiring Ready. Retries do not extend expiry.") @ApiResponse(responseCode="200",description="Rematch state") @ApiResponse(responseCode="410",description="REMATCH_EXPIRED")
 public RematchResponse request(@PathVariable UUID id,@AuthenticationPrincipal Jwt jwt){return mapper.toResponse(processor.request(id,UUID.fromString(jwt.getSubject())));}
 @GetMapping @Operation(summary="Restore private rematch state") @ApiResponse(responseCode="200",description="Rematch state")
 public RematchResponse get(@PathVariable UUID id,@AuthenticationPrincipal Jwt jwt){return mapper.toResponse(processor.get(id,UUID.fromString(jwt.getSubject())));}
 @DeleteMapping @ResponseStatus(HttpStatus.NO_CONTENT) @Operation(summary="Cancel pending rematch",description="Repeated cancellation is idempotent. A matched battle must be recovered through activity.") @ApiResponse(responseCode="204",description="Consent cancelled")
 public void cancel(@PathVariable UUID id,@AuthenticationPrincipal Jwt jwt){processor.cancel(id,UUID.fromString(jwt.getSubject()));}
}
