package com.skillbattles.backend.controller;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.mapper.MatchmakingMapper;
import com.skillbattles.backend.processor.RematchProcessor;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.headers.Header;
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
@RequestMapping("/api/v1/users/me/rematch-invitations")
@RequiredArgsConstructor
@Tag(name = "Rematch notifications")
@SecurityRequirement(name = "accessBearer")
public class RematchInvitationController {
    private final RematchProcessor processor;
    private final MatchmakingMapper mapper;

    @GetMapping
    @Operation(operationId = "getUsersMeRematchInvitations", summary = "List pending incoming rematch invitations",
            description = "Complete incoming WAITING set for JWT sub, sorted by expiresAt/sourceBattleId. No body, query or pagination. Receiving an invitation does not reserve activity. Recovery never extends the original 60-second window. Pending invitations are lost on backend restart; accepted battles recover through activity.")
    @ApiResponse(responseCode = "200", description = "Personalized incoming snapshot",
            headers = @Header(name = "Cache-Control", schema = @Schema(type = "string", allowableValues = "no-store")))
    @ApiResponse(responseCode = "401", description = "UNAUTHORIZED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "500", description = "INTERNAL_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public RematchInvitationListResponse invitations(@AuthenticationPrincipal Jwt jwt) {
        // PersonalNoStoreFilter owns the header for every /api/v1 response.
        return mapper.toResponse(processor.invitations(UUID.fromString(jwt.getSubject())));
    }
}
