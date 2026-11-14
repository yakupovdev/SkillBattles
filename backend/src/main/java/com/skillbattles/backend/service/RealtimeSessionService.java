package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.RealtimeTargetDto;
import org.springframework.web.socket.WebSocketSession;
import java.security.Principal;
import java.time.Instant;
import java.util.*;

public interface RealtimeSessionService extends PresenceService {
    void opened(WebSocketSession session);
    void touch(String sessionId);
    void authenticate(String sessionId, UUID userId, Instant expiresAt);
    void authorize(String sessionId, Principal principal);
    void reserveSubscription(String sessionId, String subscriptionId);
    void subscribed(String sessionId);
    void unsubscribe(String sessionId, String subscriptionId);
    void closed(String sessionId);
    void disconnect(String sessionId);
    void reject(String sessionId, String code, String message);
    void expireDue();
    boolean isCurrent(String sessionId);
    Optional<RealtimeTargetDto> target(UUID userId);
    boolean hasSubscribers();
}
