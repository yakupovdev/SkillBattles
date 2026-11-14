package com.skillbattles.backend.service;

import com.skillbattles.backend.config.RealtimeProperties;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.exception.RealtimeException;
import com.skillbattles.backend.handler.StompErrorHandler;
import org.springframework.beans.factory.*;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.context.annotation.Profile;
import org.springframework.messaging.simp.stomp.StompEncoder;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;
import org.springframework.stereotype.Service;
import org.springframework.web.socket.*;
import java.io.IOException;
import java.security.Principal;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.concurrent.ScheduledFuture;

/** In-memory, single-instance gameplay sessions. Raw JWTs are never retained. */
@Service
@Profile("!question-import")
public class PresenceServiceImpl implements RealtimeSessionService, SmartInitializingSingleton, DisposableBean {
    private final Clock clock;
    private final RealtimeProperties properties;
    private final ThreadPoolTaskScheduler scheduler;
    private final StompErrorHandler errors;
    private final ApplicationEventPublisher events;
    private final Map<String, Connection> connections = new HashMap<>();
    private final Map<UUID, String> active = new HashMap<>();
    private final Map<UUID, Instant> disconnected = new HashMap<>();
    private ScheduledFuture<?> monitor;

    public PresenceServiceImpl(Clock clock, RealtimeProperties properties, ThreadPoolTaskScheduler realtimeTaskScheduler,
                               StompErrorHandler errors, ApplicationEventPublisher events) {
        this.clock = clock; this.properties = properties; this.scheduler = realtimeTaskScheduler;
        this.errors = errors; this.events = events;
    }

    @Override public void afterSingletonsInstantiated() {
        monitor = scheduler.scheduleAtFixedRate(this::expireDue, Duration.ofMillis(properties.getMonitorMs()));
    }
    @Override public synchronized void opened(WebSocketSession session) { connections.put(session.getId(), new Connection(session, now())); }
    @Override public synchronized void touch(String sessionId) {
        Connection connection = connections.get(sessionId);
        if (connection != null) connection.lastRead = now();
    }

    @Override public synchronized void authenticate(String sessionId, UUID userId, Instant expiresAt) {
        Connection connection = connection(sessionId);
        if (connection.userId != null || !expiresAt.isAfter(now())) throw RealtimeException.unauthorized();
        connection.userId = userId;
        connection.expiresAt = expiresAt;
        connection.expiry = scheduler.schedule(this::expireDue, expiresAt);
    }

    @Override public synchronized void authorize(String sessionId, Principal principal) {
        Connection connection = connection(sessionId);
        if (connection.revoked || connection.userId == null || principal == null
                || !connection.userId.toString().equals(principal.getName()) || !connection.expiresAt.isAfter(now())) {
            throw RealtimeException.unauthorized();
        }
    }

    @Override public synchronized void reserveSubscription(String sessionId, String subscriptionId) {
        Connection connection = connection(sessionId);
        if (subscriptionId == null || subscriptionId.isBlank() || connection.subscriptionId != null) throw RealtimeException.forbidden();
        connection.subscriptionId = subscriptionId;
    }

    @Override public void subscribed(String sessionId) {
        Connection previous = null;
        UUID userId;
        synchronized (this) {
            Connection connection = connection(sessionId);
            if (connection.revoked || connection.userId == null || !connection.expiresAt.isAfter(now())) throw RealtimeException.unauthorized();
            if (connection.subscribed) return;
            connection.subscribed = true;
            connection.observedAt = now();
            userId = connection.userId;
            String oldId = active.put(userId, sessionId);
            if (oldId != null && !oldId.equals(sessionId)) {
                previous = connections.get(oldId);
                if (previous != null) { previous.revoked = true; previous.subscribed = false; }
            }
        }
        if (previous != null) close(previous, "Connection was replaced by a new gameplay session.");
        events.publishEvent(new PresenceChangedEvent(userId));
    }

    @Override public void unsubscribe(String sessionId, String subscriptionId) {
        UUID changed = null;
        synchronized (this) {
            Connection connection = connection(sessionId);
            if (!Objects.equals(connection.subscriptionId, subscriptionId) || subscriptionId == null) throw RealtimeException.forbidden();
            connection.subscriptionId = null;
            connection.subscribed = false;
            if (active.remove(connection.userId, sessionId)) { disconnected.put(connection.userId, now()); changed = connection.userId; }
        }
        if (changed != null) events.publishEvent(new PresenceChangedEvent(changed));
    }

    @Override public void closed(String sessionId) {
        UUID changed = null;
        synchronized (this) {
            Connection connection = connections.remove(sessionId);
            if (connection == null) return;
            if (connection.expiry != null) connection.expiry.cancel(false);
            if (active.remove(connection.userId, sessionId)) { disconnected.put(connection.userId, now()); changed = connection.userId; }
        }
        if (changed != null) events.publishEvent(new PresenceChangedEvent(changed));
    }

    @Override public void reject(String sessionId, String code, String message) {
        Connection connection;
        synchronized (this) { connection = connections.get(sessionId); }
        closed(sessionId);
        if (connection != null) close(connection, code, message);
    }

    @Override public void disconnect(String sessionId) {
        Connection connection;
        synchronized (this) { connection = connections.get(sessionId); }
        closed(sessionId);
        if (connection != null) {
            try { connection.socket.close(CloseStatus.NORMAL); } catch (IOException ignored) { }
        }
    }

    @Override public synchronized Optional<PresenceDto> current(UUID userId) {
        return observed(userId).filter(value -> value.getSessionId() != null);
    }
    @Override public synchronized Optional<PresenceDto> observed(UUID userId) {
        Connection connection = connections.get(active.get(userId));
        if (live(connection)) return Optional.of(new PresenceDto(connection.generation, connection.expiresAt, connection.observedAt, disconnected.get(userId)));
        if (connection != null) {
            // Read expiry atomically with the current generation, before the transport monitor runs.
            // A previous session's disconnect must never be mistaken for this session's expiry.
            Instant at = connection.expiresAt != null && !connection.expiresAt.isAfter(now()) ? connection.expiresAt : now();
            return Optional.of(new PresenceDto(null, null, at));
        }
        return Optional.ofNullable(disconnected.get(userId)).map(at -> new PresenceDto(null, null, at));
    }
    @Override public synchronized Optional<Instant> lastDisconnectedAt(UUID userId) { return Optional.ofNullable(disconnected.get(userId)); }
    @Override public synchronized Optional<RealtimeTargetDto> target(UUID userId) {
        Connection connection = connections.get(active.get(userId));
        return live(connection) ? Optional.of(new RealtimeTargetDto(userId, connection.socket.getId())) : Optional.empty();
    }
    @Override public synchronized boolean isCurrent(String sessionId) { return live(connections.get(sessionId)); }
    @Override public synchronized boolean hasSubscribers() { return !active.isEmpty(); }

    @Override public void expireDue() {
        List<Connection> expired;
        Instant now = now();
        synchronized (this) {
            expired = connections.values().stream().filter(connection ->
                    connection.expiresAt != null && !connection.expiresAt.isAfter(now)
                    || connection.userId == null && !connection.opened.plusMillis(properties.getConnectTimeoutMs()).isAfter(now)
                    || !connection.lastRead.plusMillis(properties.getReadTimeoutMs()).isAfter(now)).toList();
        }
        for (Connection connection : expired) {
            closed(connection.socket.getId());
            close(connection, "Authentication expired or connection heartbeat timed out.");
        }
    }

    private boolean live(Connection connection) {
        return connection != null && !connection.revoked && connection.subscribed && connection.socket.isOpen()
                && connection.expiresAt.isAfter(now()) && connection.socket.getId().equals(active.get(connection.userId));
    }
    private Connection connection(String id) {
        Connection connection = connections.get(id);
        if (connection == null || !connection.socket.isOpen()) throw RealtimeException.unauthorized();
        return connection;
    }
    private void close(Connection connection, String message) {
        close(connection, "UNAUTHORIZED", message);
    }
    private void close(Connection connection, String code, String message) {
        try {
            if (connection.socket.isOpen()) connection.socket.sendMessage(new TextMessage(new StompEncoder().encode(errors.frame(code, message))));
        } catch (IOException | RuntimeException ignored) {
            // A broken transport cannot receive ERROR. Never log frames or credentials.
        } finally {
            try { connection.socket.close(CloseStatus.POLICY_VIOLATION); } catch (IOException ignored) { }
        }
    }
    private Instant now() { return clock.instant().truncatedTo(ChronoUnit.MICROS); }
    @Override public void destroy() {
        if (monitor != null) monitor.cancel(false);
        List<Connection> remaining;
        synchronized (this) { remaining = List.copyOf(connections.values()); active.clear(); connections.clear(); }
        for (Connection connection : remaining) {
            if (connection.expiry != null) connection.expiry.cancel(false);
            try { connection.socket.close(CloseStatus.GOING_AWAY); } catch (IOException ignored) { }
        }
    }
    private static final class Connection {
        final WebSocketSession socket;
        final UUID generation = UUID.randomUUID();
        final Instant opened;
        Instant lastRead;
        UUID userId;
        Instant expiresAt;
        Instant observedAt;
        String subscriptionId;
        boolean subscribed;
        boolean revoked;
        ScheduledFuture<?> expiry;
        Connection(WebSocketSession socket, Instant now) { this.socket = socket; this.opened = now; this.lastRead = now; }
    }
}
