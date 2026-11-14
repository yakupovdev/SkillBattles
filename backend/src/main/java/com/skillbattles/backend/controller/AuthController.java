package com.skillbattles.backend.controller;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.exception.UnauthorizedException;
import com.skillbattles.backend.mapper.AuthMapper;
import com.skillbattles.backend.processor.AuthProcessor;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.*;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.server.resource.web.DefaultBearerTokenResolver;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "Stateless email/password authentication; tokens are sent in Authorization headers.")
@ApiResponse(responseCode = "500", description = "INTERNAL_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
public class AuthController {
    private final AuthProcessor processor;
    private final AuthMapper mapper;
    private final DefaultBearerTokenResolver bearerTokenResolver = new DefaultBearerTokenResolver();

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Register and log in immediately", description = "Email and nickname are unique among active users, ignoring case. No verification email is sent.")
    @ApiResponse(responseCode = "201", description = "User created and token pair issued")
    @ApiResponse(responseCode = "400", description = "VALIDATION_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "409", description = "EMAIL_ALREADY_EXISTS or NICKNAME_ALREADY_EXISTS", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        return mapper.toResponse(processor.register(mapper.toDto(request)));
    }

    @PostMapping("/login")
    @Operation(summary = "Log in with email and password", description = "Unknown email, deleted account and wrong password return the same invalid credentials error.")
    @ApiResponse(responseCode = "200", description = "Token pair issued")
    @ApiResponse(responseCode = "400", description = "VALIDATION_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "401", description = "INVALID_CREDENTIALS", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return mapper.toResponse(processor.login(mapper.toDto(request)));
    }

    @PostMapping("/refresh")
    @Operation(summary = "Rotate a refresh token", description = "Requires a refresh Bearer token and no body. The old refresh is atomically revoked; concurrent reuse has only one winner.", security = @SecurityRequirement(name = "refreshBearer"))
    @ApiResponse(responseCode = "200", description = "New token pair issued")
    @ApiResponse(responseCode = "401", description = "UNAUTHORIZED: missing, invalid, expired, revoked or wrong token type; deleted user", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public AuthResponse refresh(HttpServletRequest request) {
        return mapper.toResponse(processor.refresh(refreshToken(request)));
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Revoke this refresh token", description = "Requires a refresh Bearer token and no body. Other sessions are unaffected; access JWT remains valid until expiry. Repeated logout returns 401.", security = @SecurityRequirement(name = "refreshBearer"))
    @ApiResponse(responseCode = "204", description = "Refresh token revoked", content = @Content)
    @ApiResponse(responseCode = "401", description = "UNAUTHORIZED: missing, invalid, expired, revoked or wrong token type", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public void logout(HttpServletRequest request) { processor.logout(refreshToken(request)); }

    private String refreshToken(HttpServletRequest request) {
        String token = bearerTokenResolver.resolve(request);
        if (token == null) throw new UnauthorizedException();
        return token;
    }
}
