package com.skillbattles.backend.controller;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.mapper.BattleStickerMapper;
import com.skillbattles.backend.processor.BattleStickerProcessor;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.headers.Header;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
@RestController @RequiredArgsConstructor
@Tag(name = "Battle stickers") @SecurityRequirement(name = "accessBearer")
public class BattleStickerController {
    private final BattleStickerProcessor processor;
    private final BattleStickerMapper mapper;
    @PostMapping("/api/v1/battles/{id}/stickers")
    @Operation(operationId = "sendBattleSticker", summary = "Send an ephemeral sticker to the other battle participant", description = "New sends in WAITING_READY, COUNTDOWN, QUESTION or REVEAL only. All plans/modes/disciplines. Per-user 4000ms cooldown across sessions/battles. Identical sender/submissionId retries return the original receipt for 120s, including after termination; never re-emit. 200 confirms acceptance, not delivery. Opponent-only BATTLE_STICKER uses the existing personal native STOMP channel and a separate battle sticker sequence. Process restart clears all sticker state; no history or replay.")
    @ApiResponse(responseCode = "200", description = "New acceptance or original retained receipt", headers = @Header(name = "Cache-Control", schema = @Schema(type = "string", allowableValues = "no-store")))
    @ApiResponse(responseCode = "400", description = "VALIDATION_ERROR; INVALID_STICKER_ID", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "401", description = "UNAUTHORIZED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "404", description = "BATTLE_NOT_FOUND: missing or not a participant", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "409", description = "STICKERS_NOT_ALLOWED; IDEMPOTENCY_CONFLICT", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "429", description = "STICKER_COOLDOWN: quietly synchronize the frontend timer; resetsAt is exact nextAllowedAt", headers = @Header(name = "Retry-After", description = "Ceiling remaining seconds, minimum 1", schema = @Schema(type = "integer", minimum = "1")), content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "500", description = "INTERNAL_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public StickerSendResponse send(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt, @Valid @RequestBody SendBattleStickerRequest request) {
        return mapper.toResponse(processor.send(id, UUID.fromString(jwt.getSubject()), mapper.toDto(request)));
    }
}
