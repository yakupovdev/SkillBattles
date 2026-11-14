package com.skillbattles.backend.config;

import com.skillbattles.backend.handler.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillbattles.backend.service.RealtimeSessionService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.*;
import org.springframework.http.*;
import org.springframework.http.server.*;
import org.springframework.messaging.*;
import org.springframework.messaging.simp.SimpMessageType;
import org.springframework.messaging.simp.config.*;
import org.springframework.messaging.support.ExecutorChannelInterceptor;
import org.springframework.messaging.converter.*;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;
import org.springframework.web.socket.*;
import org.springframework.web.socket.config.annotation.*;
import org.springframework.web.socket.handler.*;
import org.springframework.web.socket.server.HandshakeInterceptor;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Configuration
@Profile("!question-import")
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
public class RealtimeWebSocketConfig implements WebSocketMessageBrokerConfigurer {
    private final StompAuthInterceptor auth;
    private final StompErrorHandler errors;
    private final RealtimeSessionService sessions;
    private final RealtimeProperties properties;
    private final ThreadPoolTaskScheduler realtimeTaskScheduler;
    private final ObjectMapper objectMapper;

    @Override public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.setErrorHandler(errors).setPreserveReceiveOrder(true);
        // Default allowedOrigins is same-origin. No SockJS or wildcard origin configuration.
        registry.addEndpoint("/ws/v1/events").addInterceptors(new HandshakeInterceptor() {
            @Override public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response, WebSocketHandler handler, Map<String, Object> attributes) {
                if (request.getURI().getRawQuery() != null) { response.setStatusCode(HttpStatus.BAD_REQUEST); return false; }
                return true;
            }
            @Override public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response, WebSocketHandler handler, Exception ex) { }
        });
    }

    @Override public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/queue").setHeartbeatValue(new long[] {properties.getHeartbeatMs(), properties.getHeartbeatMs()}).setTaskScheduler(realtimeTaskScheduler);
        registry.setUserDestinationPrefix("/user");
        registry.setApplicationDestinationPrefixes("/app");
        registry.setPreservePublishOrder(true);
    }

    @Override public void configureClientInboundChannel(ChannelRegistration registration) {
        // Token-only message security is enforced here. @EnableWebSocketSecurity and its
        // CsrfChannelInterceptor are intentionally absent; same-origin handshake checks remain active.
        registration.interceptors(auth);
    }

    @Override public boolean configureMessageConverters(List<MessageConverter> converters) {
        MappingJackson2MessageConverter json = new MappingJackson2MessageConverter();
        json.setObjectMapper(objectMapper);
        converters.add(json);
        return true;
    }

    @Override public void configureClientOutboundChannel(ChannelRegistration registration) {
        registration.interceptors(new ExecutorChannelInterceptor() {
            @Override public Message<?> preSend(Message<?> message, MessageChannel channel) {
                var type = org.springframework.messaging.simp.SimpMessageHeaderAccessor.getMessageType(message.getHeaders());
                String id = org.springframework.messaging.simp.SimpMessageHeaderAccessor.getSessionId(message.getHeaders());
                return type == SimpMessageType.MESSAGE && !sessions.isCurrent(id) ? null : message;
            }
            @Override public void afterMessageHandled(Message<?> message, MessageChannel channel, MessageHandler handler, Exception exception) {
                if (org.springframework.messaging.simp.SimpMessageHeaderAccessor.getMessageType(message.getHeaders()) == SimpMessageType.DISCONNECT_ACK) {
                    // Close only after the framework has delivered the requested STOMP receipt.
                    sessions.disconnect(org.springframework.messaging.simp.SimpMessageHeaderAccessor.getSessionId(message.getHeaders()));
                }
            }
        });
    }

    @Override public void configureWebSocketTransport(WebSocketTransportRegistration registration) {
        registration.setMessageSizeLimit(16 * 1024).setSendBufferSizeLimit(128 * 1024).setSendTimeLimit(5000)
                .setTimeToFirstMessage((int) properties.getConnectTimeoutMs());
        registration.addDecoratorFactory(handler -> new WebSocketHandlerDecorator(handler) {
            private final Map<String, WebSocketSession> wrapped = new ConcurrentHashMap<>();
            @Override public void afterConnectionEstablished(WebSocketSession session) throws Exception {
                WebSocketSession safe = new ConcurrentWebSocketSessionDecorator(session, 5000, 128 * 1024);
                wrapped.put(session.getId(), safe);
                sessions.opened(safe);
                super.afterConnectionEstablished(safe);
            }
            @Override public void handleMessage(WebSocketSession session, WebSocketMessage<?> message) throws Exception {
                sessions.touch(session.getId());
                super.handleMessage(wrapped.getOrDefault(session.getId(), session), message);
            }
            @Override public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
                try { super.afterConnectionClosed(wrapped.getOrDefault(session.getId(), session), status); }
                finally { wrapped.remove(session.getId()); sessions.closed(session.getId()); }
            }
        });
    }
}
