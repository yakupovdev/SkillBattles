package com.skillbattles.backend;

import com.fasterxml.jackson.databind.*;
import java.net.URI;
import java.net.http.*;
import java.time.Duration;
import java.util.*;
import java.util.concurrent.*;
import java.util.function.Predicate;

/** Real native WebSocket transport with STOMP frames; no server-side test endpoint. */
final class NativeStompClient implements WebSocket.Listener, AutoCloseable {
    private final BlockingQueue<Frame> frames = new LinkedBlockingQueue<>();
    private final StringBuilder pending = new StringBuilder();
    final CompletableFuture<Integer> closed = new CompletableFuture<>();
    private final ScheduledExecutorService heartbeats = Executors.newSingleThreadScheduledExecutor(runnable -> {
        Thread thread = new Thread(runnable, "test-stomp-heartbeat"); thread.setDaemon(true); return thread;
    });
    private WebSocket socket;
    private final ObjectMapper mapper;

    NativeStompClient(HttpClient http, URI uri, String origin, ObjectMapper mapper) throws Exception {
        this.mapper = mapper;
        socket = http.newWebSocketBuilder().header("Origin", origin).connectTimeout(Duration.ofSeconds(5)).buildAsync(uri, this).get(6, TimeUnit.SECONDS);
    }

    void connect(String token) throws Exception {
        send("CONNECT\naccept-version:1.2\nhost:localhost\nheart-beat:5000,5000\n"
                + (token == null ? "" : "Authorization:Bearer " + token + "\n") + "\n\0");
    }

    void subscribe(String destination) throws Exception { send("SUBSCRIBE\nid:events\ndestination:" + destination + "\nack:auto\n\n\0"); }
    void send(String frame) throws Exception { socket.sendText(frame, true).get(5, TimeUnit.SECONDS); }
    void startHeartbeats() { heartbeats.scheduleAtFixedRate(() -> {
        if (!socket.isOutputClosed()) socket.sendText("\n", true);
    }, 1, 1, TimeUnit.SECONDS); }
    void stopHeartbeats() { heartbeats.shutdownNow(); }

    Frame await(String command) throws Exception {
        long until = System.nanoTime() + TimeUnit.SECONDS.toNanos(5);
        while (System.nanoTime() < until) {
            Frame frame = frames.poll(100, TimeUnit.MILLISECONDS);
            if (frame != null && frame.command().equals(command)) return frame;
        }
        throw new AssertionError("Timed out waiting for STOMP " + command);
    }

    JsonNode event(Predicate<JsonNode> condition) throws Exception {
        long until = System.nanoTime() + TimeUnit.SECONDS.toNanos(5);
        while (System.nanoTime() < until) {
            Frame frame = frames.poll(100, TimeUnit.MILLISECONDS);
            if (frame != null && frame.command().equals("MESSAGE")) {
                JsonNode event = mapper.readTree(frame.body());
                if (condition.test(event)) return event;
            }
        }
        throw new AssertionError("Timed out waiting for personalized battle event");
    }

    void drain() { frames.clear(); }
    boolean hasMessage(Duration timeout) throws Exception {
        long until = System.nanoTime() + timeout.toNanos();
        while (System.nanoTime() < until) {
            Frame frame = frames.poll(25, TimeUnit.MILLISECONDS);
            if (frame != null && frame.command().equals("MESSAGE")) return true;
        }
        return false;
    }

    @Override public void onOpen(WebSocket webSocket) { webSocket.request(1); }
    @Override public CompletionStage<?> onText(WebSocket webSocket, CharSequence data, boolean last) {
        synchronized (pending) {
            pending.append(data);
            while (true) {
                int end = pending.indexOf("\0");
                if (end < 0) break;
                String raw = pending.substring(0, end).stripLeading().replace("\r\n", "\n");
                pending.delete(0, end + 1);
                if (!raw.isBlank()) frames.add(Frame.parse(raw));
            }
            if (pending.toString().isBlank()) pending.setLength(0);
        }
        webSocket.request(1);
        return CompletableFuture.completedFuture(null);
    }
    @Override public CompletionStage<?> onClose(WebSocket webSocket, int statusCode, String reason) {
        closed.complete(statusCode); return CompletableFuture.completedFuture(null);
    }
    @Override public void onError(WebSocket webSocket, Throwable error) { closed.completeExceptionally(error); }

    @Override public void close() {
        heartbeats.shutdownNow();
        if (socket != null && !socket.isOutputClosed()) socket.sendClose(WebSocket.NORMAL_CLOSURE, "Test finished");
    }

    record Frame(String command, Map<String, String> headers, String body) {
        static Frame parse(String raw) {
            int split = raw.indexOf("\n\n");
            String[] lines = (split < 0 ? raw : raw.substring(0, split)).split("\n");
            Map<String, String> headers = new HashMap<>();
            for (int i = 1; i < lines.length; i++) {
                int colon = lines[i].indexOf(':');
                if (colon > 0) headers.put(lines[i].substring(0, colon), lines[i].substring(colon + 1));
            }
            return new Frame(lines[0], headers, split < 0 ? "" : raw.substring(split + 2));
        }
    }
}
