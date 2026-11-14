package com.skillbattles.backend.exception;

import org.springframework.http.HttpStatus;

public class GoneException extends BusinessException {
    public GoneException(String code, String message) { super(code, message, HttpStatus.GONE); }
}
