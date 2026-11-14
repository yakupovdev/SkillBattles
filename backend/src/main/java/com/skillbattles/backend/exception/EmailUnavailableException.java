package com.skillbattles.backend.exception;
import org.springframework.http.HttpStatus;
public class EmailUnavailableException extends BusinessException { public EmailUnavailableException(){super("EMAIL_SERVICE_UNAVAILABLE","Password reset email is unavailable.",HttpStatus.SERVICE_UNAVAILABLE);} }
