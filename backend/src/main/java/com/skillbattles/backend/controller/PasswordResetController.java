package com.skillbattles.backend.controller;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.processor.PasswordResetProcessor;
import lombok.RequiredArgsConstructor;
import jakarta.validation.Valid;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.HttpStatus;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
@RestController @RequestMapping("/api/v1/auth/password-reset") @RequiredArgsConstructor
@ApiResponse(responseCode="400",description="VALIDATION_ERROR or INVALID_RESET_TOKEN")
@ApiResponse(responseCode="429",description="RATE_LIMITED")
@ApiResponse(responseCode="500",description="INTERNAL_ERROR")
public class PasswordResetController {
 private final PasswordResetProcessor processor;
 @PostMapping("/request") @ResponseStatus(HttpStatus.ACCEPTED)
 @Operation(summary="Request password reset",description="Generic response for existing and unknown email; delivery is asynchronous.")
 @ApiResponse(responseCode="202",description="Instructions queued if an account exists")
 @ApiResponse(responseCode="503",description="EMAIL_SERVICE_UNAVAILABLE")
 public AcceptedResponse request(@Valid @RequestBody PasswordResetRequest body,HttpServletRequest request){processor.request(body.getEmail(),request.getRemoteAddr());return new AcceptedResponse("If an account exists, password reset instructions will be sent.");}
 @PostMapping("/confirm") @ResponseStatus(HttpStatus.NO_CONTENT)
 @Operation(summary="Consume a password reset token",description="One use within 20 minutes; revokes all refresh tokens, access tokens retain their expiry.")
 @ApiResponse(responseCode="204",description="Password changed")
 public void confirm(@Valid @RequestBody PasswordResetConfirmRequest body,HttpServletRequest request){processor.confirm(body.getToken(),body.getNewPassword(),request.getRemoteAddr());}
}
