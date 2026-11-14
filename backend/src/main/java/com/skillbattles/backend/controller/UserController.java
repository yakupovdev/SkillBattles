package com.skillbattles.backend.controller;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.mapper.UserMapper;
import com.skillbattles.backend.service.UserService;
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
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Tag(name = "Users")
public class UserController {
    private final UserService service;
    private final com.skillbattles.backend.processor.ProfileProcessor profiles;
    private final com.skillbattles.backend.processor.AccountProcessor accounts;
    private final UserMapper mapper;

    @PatchMapping("/me")
    @Operation(summary="Update nickname or password", security=@SecurityRequirement(name="accessBearer"))
    @ApiResponse(responseCode="200",description="Profile updated; password change revokes every refresh token")
    @ApiResponse(responseCode="400",description="VALIDATION_ERROR or EMPTY_UPDATE")
    @ApiResponse(responseCode="401",description="UNAUTHORIZED or INVALID_CURRENT_PASSWORD")
    @ApiResponse(responseCode="409",description="NICKNAME_ALREADY_EXISTS")
    public UpdateProfileResponse update(@AuthenticationPrincipal Jwt jwt,@jakarta.validation.Valid @RequestBody UpdateProfileRequest request) {
        var user=profiles.update(UUID.fromString(jwt.getSubject()),mapper.toDto(request)); boolean changed=request.getNewPassword()!=null;
        return new UpdateProfileResponse(mapper.toResponse(user),changed,changed);
    }
    @GetMapping("/me")
    @Operation(summary = "Get the current active user", description = "Returns the owner's profile without password hashes.", security = @SecurityRequirement(name = "accessBearer"))
    @ApiResponse(responseCode = "200", description = "Current user")
    @ApiResponse(responseCode = "401", description = "UNAUTHORIZED", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "403", description = "FORBIDDEN", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "404", description = "USER_NOT_FOUND: account was deleted", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    @ApiResponse(responseCode = "500", description = "INTERNAL_ERROR", content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    public UserResponse me(@AuthenticationPrincipal Jwt jwt) {
        return mapper.toResponse(accounts.state(UUID.fromString(jwt.getSubject())).getUser());
    }
}
