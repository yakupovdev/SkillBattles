package com.skillbattles.backend.controller;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.processor.SubscriptionProcessor;
import com.skillbattles.backend.mapper.BillingMapper;
import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import java.util.UUID;

@RestController @RequestMapping("/api/v1/subscriptions") @RequiredArgsConstructor
@ApiResponse(responseCode="500",description="INTERNAL_ERROR",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
public class SubscriptionController {
    private final SubscriptionProcessor processor;
    private final BillingMapper mapper;

    @GetMapping("/me") @Operation(operationId="getSubscriptionMe",summary="Get own Pro status and current rights",security=@SecurityRequirement(name="accessBearer"))
    @ApiResponse(responseCode="200",description="Current access; new registrations receive permanent Pro")
    @ApiResponse(responseCode="401",description="UNAUTHORIZED",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public SubscriptionResponse me(@AuthenticationPrincipal Jwt jwt){
        return mapper.toResponse(processor.current(UUID.fromString(jwt.getSubject())));
    }
}
