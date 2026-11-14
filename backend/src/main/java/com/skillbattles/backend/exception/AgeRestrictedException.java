package com.skillbattles.backend.exception;
import org.springframework.http.HttpStatus;
public class AgeRestrictedException extends BusinessException {
    public AgeRestrictedException() { super("AGE_RESTRICTED", "You must be at least 13 to register.", HttpStatus.FORBIDDEN); }
}
