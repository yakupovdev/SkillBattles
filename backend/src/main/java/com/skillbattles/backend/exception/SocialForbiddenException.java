package com.skillbattles.backend.exception;
import org.springframework.http.HttpStatus;
public class SocialForbiddenException extends BusinessException {
    public SocialForbiddenException() { super("FORBIDDEN","This action is not allowed for this participant.",HttpStatus.FORBIDDEN); }
}
