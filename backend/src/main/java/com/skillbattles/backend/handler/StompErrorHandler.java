package com.skillbattles.backend.handler;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillbattles.backend.dto.ErrorResponse;
import com.skillbattles.backend.exception.RealtimeException;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.http.MediaType;
import org.springframework.messaging.*;
import org.springframework.messaging.simp.stomp.*;
import org.springframework.web.socket.messaging.StompSubProtocolErrorHandler;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.stereotype.Component;

@Component
@Profile("!question-import")
@RequiredArgsConstructor
public class StompErrorHandler extends StompSubProtocolErrorHandler {
    private final ObjectMapper mapper;

    @Override
    public Message<byte[]> handleClientMessageProcessingError(Message<byte[]> clientMessage, Throwable exception) {
        for (Throwable cause = exception; cause != null; cause = cause.getCause()) {
            if (cause instanceof RealtimeException error) return frame(error.getCode(), error.getMessage());
        }
        if (clientMessage != null) {
            StompHeaderAccessor headers = StompHeaderAccessor.wrap(clientMessage);
            if (headers.getUser() == null && headers.getCommand() != StompCommand.CONNECT && headers.getCommand() != StompCommand.STOMP) {
                return frame("UNAUTHORIZED", "Authentication required.");
            }
        }
        return frame("VALIDATION_ERROR", "Invalid STOMP frame.");
    }

    public Message<byte[]> frame(String code, String message) {
        byte[] payload;
        try { payload = mapper.writeValueAsBytes(ErrorResponse.of(code, message)); }
        catch (java.io.IOException ex) { throw new IllegalStateException("Cannot encode STOMP error."); }
        StompHeaderAccessor headers = StompHeaderAccessor.create(StompCommand.ERROR);
        headers.setMessage(message);
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setContentLength(payload.length);
        return MessageBuilder.createMessage(payload, headers.getMessageHeaders());
    }
}
