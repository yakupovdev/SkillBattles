package com.skillbattles.backend.controller;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.processor.AccountProcessor;
import com.skillbattles.backend.mapper.BillingMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import java.util.UUID;
@RestController @RequestMapping("/api/v1/users/me/limits") @RequiredArgsConstructor @SecurityRequirement(name="accessBearer")
public class LimitsController {
    private final AccountProcessor accounts;private final BillingMapper mapper;
    @GetMapping @Operation(operationId="getUsersMeLimits",summary="Get current ET ranked quota and entitlements")
    @ApiResponse(responseCode="200",description="Current day usage, including starts while Pro")
    @ApiResponse(responseCode="401",description="UNAUTHORIZED",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="404",description="USER_NOT_FOUND",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="500",description="INTERNAL_ERROR",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public LimitsResponse limits(@AuthenticationPrincipal Jwt jwt){return mapper.toResponse(accounts.state(UUID.fromString(jwt.getSubject())).getLimits());}
}
