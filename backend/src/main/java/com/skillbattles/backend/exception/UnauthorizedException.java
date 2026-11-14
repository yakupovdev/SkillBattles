package com.skillbattles.backend.exception;

import org.springframework.http.HttpStatus;

public class UnauthorizedException extends BusinessException {
    public UnauthorizedException() { this("UNAUTHORIZED", "Authentication required."); }
    public UnauthorizedException(String code, String message) { super(code, message, HttpStatus.UNAUTHORIZED); }
}
