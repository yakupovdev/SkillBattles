package com.skillbattles.backend.exception;

import lombok.Getter;

@Getter
public class RealtimeException extends RuntimeException {
    private final String code;
    public RealtimeException(String code, String message) { super(message); this.code = code; }
    public static RealtimeException unauthorized() { return new RealtimeException("UNAUTHORIZED", "Authentication required."); }
    public static RealtimeException forbidden() { return new RealtimeException("FORBIDDEN", "STOMP command or destination is not allowed."); }
}
