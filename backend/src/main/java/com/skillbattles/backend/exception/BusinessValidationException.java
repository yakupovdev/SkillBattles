package com.skillbattles.backend.exception;

import org.springframework.http.HttpStatus;

public class BusinessValidationException extends BusinessException {
    public BusinessValidationException(String code, String message) { super(code, message, HttpStatus.BAD_REQUEST); }
}
