package com.skillbattles.backend.handler;

import com.skillbattles.backend.config.RealtimeProperties;
import com.skillbattles.backend.exception.RealtimeException;
import com.skillbattles.backend.service.RealtimeSessionService;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Profile;
import org.springframework.messaging.*;
import org.springframework.messaging.simp.SimpMessageType;
import org.springframework.messaging.simp.stomp.*;
import org.springframework.messaging.simp.user.UserDestinationMessageHandler;
import org.springframework.messaging.support.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.stereotype.Component;
import java.util.*;

@Component
@Profile("!question-import")
public class StompAuthInterceptor implements ExecutorChannelInterceptor {
    public static final String DESTINATION = "/user/queue/events";
    private final JwtDecoder decoder;
    private final RealtimeSessionService sessions;
    private final RealtimeProperties properties;

    public StompAuthInterceptor(@Qualifier("accessJwtDecoder") JwtDecoder decoder, RealtimeSessionService sessions, RealtimeProperties properties) {
        this.decoder = decoder; this.sessions = sessions; this.properties = properties;
    }

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        try { return authorize(message); }
        catch (RealtimeException error) {
            String sessionId = org.springframework.messaging.simp.SimpMessageHeaderAccessor.getSessionId(message.getHeaders());
            // Ordered inbound channels can swallow interceptor exceptions. Send the sanitized ERROR
            // and close explicitly, rather than relying on exception propagation through that queue.
            sessions.reject(sessionId, error.getCode(), error.getMessage());
            return null;
        }
    }

    private Message<?> authorize(Message<?> message) {
        StompHeaderAccessor headers = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (headers == null) throw RealtimeException.forbidden();
        StompCommand command = headers.getCommand();
        List<String> authorization = headers.getNativeHeader("Authorization");
        // Strip credentials before dispatching to any handler, broker or error path.
        new ArrayList<>(headers.toNativeHeaderMap().keySet()).stream().filter(name -> "Authorization".equalsIgnoreCase(name))
                .forEach(headers::removeNativeHeader);
        if (command == StompCommand.CONNECT || command == StompCommand.STOMP) {
            if (authorization == null || authorization.size() != 1 || !authorization.getFirst().startsWith("Bearer ")) throw RealtimeException.unauthorized();
            if (!headers.getAcceptVersion().contains("1.2")) throw RealtimeException.forbidden();
            long[] heartbeat = headers.getHeartbeat();
            if (heartbeat[0] <= 0 || heartbeat[0] > properties.getHeartbeatMs() || heartbeat[1] <= 0 || heartbeat[1] > properties.getHeartbeatMs()) throw RealtimeException.forbidden();
            try {
                Jwt jwt = decoder.decode(authorization.getFirst().substring(7));
                UUID userId = UUID.fromString(jwt.getSubject());
                sessions.authenticate(headers.getSessionId(), userId, jwt.getExpiresAt());
                headers.setUser(UsernamePasswordAuthenticationToken.authenticated(userId.toString(), "", List.of()));
                return message;
            } catch (JwtException | IllegalArgumentException ex) { throw RealtimeException.unauthorized(); }
        }
        if (command == StompCommand.DISCONNECT) return message;
        sessions.authorize(headers.getSessionId(), headers.getUser());
        if (authorization != null) throw RealtimeException.forbidden();
        if (headers.getMessageType() == SimpMessageType.HEARTBEAT) return message;
        if (command == StompCommand.SUBSCRIBE) {
            if (!DESTINATION.equals(headers.getDestination()) || headers.getAck() != null && !"auto".equals(headers.getAck())) throw RealtimeException.forbidden();
            sessions.reserveSubscription(headers.getSessionId(), headers.getSubscriptionId());
            return message;
        }
        if (command == StompCommand.UNSUBSCRIBE) {
            sessions.unsubscribe(headers.getSessionId(), headers.getSubscriptionId());
            return message;
        }
        throw RealtimeException.forbidden();
    }

    @Override
    public void afterMessageHandled(Message<?> message, MessageChannel channel, MessageHandler handler, Exception exception) {
        if (exception != null || !(handler instanceof UserDestinationMessageHandler)) return;
        StompHeaderAccessor headers = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (headers == null) return;
        if (headers.getCommand() == StompCommand.SUBSCRIBE) {
            try { sessions.subscribed(headers.getSessionId()); }
            catch (RealtimeException ignored) { /* Transport closed while the subscription was being handled. */ }
        }
    }
}
