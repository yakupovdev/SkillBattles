package com.skillbattles.backend.exception;
import org.springframework.http.HttpStatus;
public class HistoryAccessException extends BusinessException {
    public HistoryAccessException() {super("HISTORY_ACCESS_REQUIRED","Pro is required to access this battle.",HttpStatus.FORBIDDEN);}
}
