package com.skillbattles.backend.controller;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.processor.BillingProcessor;
import com.skillbattles.backend.mapper.BillingMapper;
import com.skillbattles.backend.exception.BusinessValidationException;
import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.http.*;
import jakarta.validation.Valid;
import jakarta.servlet.http.HttpServletRequest;
import java.util.*;
@RestController @RequestMapping("/api/v1/subscriptions") @RequiredArgsConstructor
@ApiResponse(responseCode="400",description="VALIDATION_ERROR",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
@ApiResponse(responseCode="500",description="INTERNAL_ERROR",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
public class SubscriptionController {
    private final BillingProcessor processor;private final BillingMapper mapper;
    @GetMapping("/plans") @Operation(operationId="getSubscriptionPlans",summary="Get Free and Stripe TEST subscription plans")
    @ApiResponse(responseCode="200",description="Public plan catalogue; no provider price IDs or secrets")
    public List<SubscriptionPlan> plans(){return processor.plans().stream().map(mapper::toResponse).toList();}
    @GetMapping("/me") @Operation(operationId="getSubscriptionMe",summary="Get own verified subscription and current rights",security=@SecurityRequirement(name="accessBearer"))
    @ApiResponse(responseCode="200",description="Current subscription") @ApiResponse(responseCode="401",description="UNAUTHORIZED",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public SubscriptionResponse me(@AuthenticationPrincipal Jwt jwt){return mapper.toResponse(processor.current(UUID.fromString(jwt.getSubject())));}
    @PostMapping("/checkout") @Operation(operationId="postSubscriptionCheckout",summary="Create or replay own Stripe-hosted TEST checkout",security=@SecurityRequirement(name="accessBearer"))
    @ApiResponse(responseCode="200",description="Stripe-hosted checkout")
    @ApiResponse(responseCode="401",description="UNAUTHORIZED",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="409",description="SUBSCRIPTION_ALREADY_ACTIVE, CHECKOUT_IN_PROGRESS",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="503",description="BILLING_UNAVAILABLE",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public CheckoutResponse checkout(@AuthenticationPrincipal Jwt jwt,@Valid @RequestBody CheckoutRequest request){return mapper.toResponse(processor.checkout(UUID.fromString(jwt.getSubject()),request.getPlanCode(),request.getRequestId()));}
    @PostMapping("/portal") @Operation(operationId="postSubscriptionPortal",summary="Open own Stripe TEST customer portal",security=@SecurityRequirement(name="accessBearer"))
    @ApiResponse(responseCode="200",description="Stripe-hosted portal")
    @ApiResponse(responseCode="401",description="UNAUTHORIZED",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="409",description="BILLING_CUSTOMER_NOT_FOUND",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="503",description="BILLING_UNAVAILABLE",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public PortalResponse portal(@AuthenticationPrincipal Jwt jwt,@io.swagger.v3.oas.annotations.Parameter(hidden=true) @RequestBody(required=false) byte[] body){if(body!=null&&body.length>0)throw new BusinessValidationException("VALIDATION_ERROR","This operation accepts no body.");return mapper.toResponse(processor.portal(UUID.fromString(jwt.getSubject())));}
    @PostMapping(value="/webhook",consumes=MediaType.APPLICATION_JSON_VALUE) @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(operationId="postSubscriptionWebhook",summary="Verify raw Stripe TEST webhook and reconcile current provider state",security=@SecurityRequirement(name="stripeSignature"))
    @ApiResponse(responseCode="204",description="Committed event or idempotent replay")
    @ApiResponse(responseCode="400",description="INVALID_WEBHOOK_SIGNATURE, INVALID_WEBHOOK_EVENT",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    @ApiResponse(responseCode="503",description="BILLING_UNAVAILABLE; retry delivery",content=@Content(schema=@Schema(implementation=ErrorResponse.class)))
    public void webhook(@io.swagger.v3.oas.annotations.parameters.RequestBody(content=@Content(schema=@Schema(implementation=StripeEventRequest.class))) @RequestBody byte[] raw,@RequestHeader(value="Stripe-Signature",required=false) String signature){processor.webhook(raw,signature);}
}
