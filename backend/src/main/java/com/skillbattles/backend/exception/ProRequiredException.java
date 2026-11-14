package com.skillbattles.backend.exception;
import org.springframework.http.HttpStatus;
public class ProRequiredException extends BusinessException {public ProRequiredException(){super("PRO_REQUIRED","This feature requires Pro.",HttpStatus.FORBIDDEN);}}
