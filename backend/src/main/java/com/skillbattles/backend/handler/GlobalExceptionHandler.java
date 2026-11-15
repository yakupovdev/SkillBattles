package com.skillbattles.backend.handler;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.exception.BusinessException;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.*;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;
import java.util.List;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {
    private final java.time.Clock clock;
    public GlobalExceptionHandler(java.time.Clock clock){this.clock=clock;}
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ErrorResponse> business(BusinessException ex) {
        if(ex instanceof com.skillbattles.backend.exception.RateLimitedException rate) return ResponseEntity.status(429).header("Retry-After",Long.toString(rate.getRetryAfter())).body(ErrorResponse.of(rate.getCode(),rate.getMessage()));
        if(ex instanceof com.skillbattles.backend.exception.FieldValidationException field)
            return ResponseEntity.badRequest().body(new ErrorResponse(ex.getCode(),ex.getMessage(),List.of(new FieldErrorDto(field.getField(),ex.getMessage()))));
        if(ex instanceof com.skillbattles.backend.exception.DailyLimitException limit) {
            long retry=Math.max(1,java.time.Duration.between(clock.instant(),limit.getResetsAt()).getSeconds());
            return ResponseEntity.status(ex.getStatus()).header("Retry-After",Long.toString(retry)).body(new ErrorResponse(ex.getCode(),ex.getMessage(),List.of(),limit.getResetsAt()));
        }
        return ResponseEntity.status(ex.getStatus()).body(ErrorResponse.of(ex.getCode(), ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> validation(MethodArgumentNotValidException ex) {
        List<FieldErrorDto> errors = ex.getBindingResult().getFieldErrors().stream()
                .map(error -> new FieldErrorDto(error.getField(), error.getDefaultMessage())).toList();
        return ResponseEntity.badRequest().body(new ErrorResponse("VALIDATION_ERROR", "Request validation failed.", errors));
    }

    @ExceptionHandler({HttpMessageNotReadableException.class, MethodArgumentTypeMismatchException.class,
            ConstraintViolationException.class})
    public ResponseEntity<ErrorResponse> malformed(Exception ex) {
        return ResponseEntity.badRequest().body(ErrorResponse.of("VALIDATION_ERROR", "Request validation failed."));
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ErrorResponse> authentication(AuthenticationException ex) {
        return ResponseEntity.status(401).body(ErrorResponse.of("UNAUTHORIZED", "Authentication required."));
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> denied(AccessDeniedException ex) {
        return ResponseEntity.status(403).body(ErrorResponse.of("FORBIDDEN", "Access denied."));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ErrorResponse> integrity(DataIntegrityViolationException ex) {
        for (Throwable cause = ex; cause != null; cause = cause.getCause()) {
            if (cause instanceof org.hibernate.exception.ConstraintViolationException constraint) {
                if ("ux_users_active_email".equals(constraint.getConstraintName())) {
                    return ResponseEntity.status(409).body(ErrorResponse.of("EMAIL_ALREADY_EXISTS", "Email is already in use."));
                }
                if ("ux_users_active_nickname".equals(constraint.getConstraintName())) {
                    return ResponseEntity.status(409).body(ErrorResponse.of("NICKNAME_ALREADY_EXISTS", "Nickname is already in use."));
                }
            }
        }
        return internal(ex);
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ErrorResponse> missing(NoResourceFoundException ex, jakarta.servlet.http.HttpServletRequest request) {
        if (HttpMethod.HEAD.matches(request.getMethod())) return ResponseEntity.notFound().build();
        return ResponseEntity.status(404).body(ErrorResponse.of("NOT_FOUND", "Resource not found."));
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ErrorResponse> method(HttpRequestMethodNotSupportedException ex) {
        return ResponseEntity.status(405).body(ErrorResponse.of("METHOD_NOT_ALLOWED", "HTTP method is not supported."));
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<ErrorResponse> media(HttpMediaTypeNotSupportedException ex) {
        return ResponseEntity.status(415).body(ErrorResponse.of("UNSUPPORTED_MEDIA_TYPE", "Content type is not supported."));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> internal(Exception ex) {
        // Do not log exception messages or SQL parameters: they may contain credentials.
        log.error("Unhandled request failure: {}", ex.getClass().getName());
        return ResponseEntity.internalServerError().body(ErrorResponse.of("INTERNAL_ERROR", "An unexpected error occurred."));
    }
}
