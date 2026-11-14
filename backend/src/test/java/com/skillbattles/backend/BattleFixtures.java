package com.skillbattles.backend;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import com.skillbattles.backend.service.PresenceService;

/** Internal-only fixtures; never wired into the production application. */
public final class BattleFixtures {
    public static final Instant START = Instant.parse("2026-11-14T12:00:00Z");

    public static BattleDto waiting(int rounds, BattleMode mode, int firstRating, int secondRating) {
        BattleDto battle = new BattleDto();
        battle.setId(UUID.randomUUID());
        battle.setSubject(Subject.MATH);
        battle.setMode(mode);
        battle.setPhase(BattlePhase.WAITING_READY);
        battle.setVersion(1);
        battle.setReadyDeadline(START.plusSeconds(30));
        BattleStateDto state = new BattleStateDto();
        state.setLimitSeconds(10);
        state.setCountdownSeconds(3);
        state.setRevealSeconds(5);
        state.setReconnectGraceSeconds(30);
        for (int rating : List.of(firstRating, secondRating)) {
            BattlePlayerDto player = new BattlePlayerDto();
            player.setId(UUID.randomUUID());
            player.setNickname("TestPlayer" + state.getPlayers().size());
            player.setRating(rating);
            player.setConnected(true);
            player.setSessionId(UUID.randomUUID());
            player.setSessionExpiresAt(START.plusSeconds(3600));
            state.getPlayers().add(player);
        }
        for (int i = 0; i < rounds; i++) {
            List<FrozenOptionDto> options = new ArrayList<>();
            for (String key : List.of("A", "B", "C", "D")) options.add(new FrozenOptionDto(UUID.randomUUID(), "TEST ONLY " + key));
            BattleRoundDto round = new BattleRoundDto();
            round.setId(UUID.randomUUID());
            round.setNumber(i + 1);
            round.setQuestion(new FrozenQuestionDto(UUID.randomUUID(), Subject.MATH, "Test only", "TEST ONLY question " + i,
                    options, options.getFirst().getId(), "TEST ONLY secret explanation"));
            state.getRounds().add(round);
        }
        battle.setState(state);
        return battle;
    }

    public static UUID player(BattleDto battle, int index) { return battle.getState().getPlayers().get(index).getId(); }
    public static BattleRoundDto round(BattleDto battle) { return battle.getState().getRounds().get(battle.getState().getCurrentRoundIndex()); }
    public static AnswerDto answer(BattleDto battle, boolean correct) {
        var round = round(battle);
        return new AnswerDto(round.getId(), round.getQuestion().getOptions().get(correct ? 0 : 1).getId(), UUID.randomUUID());
    }

    public static final class MutableClock extends Clock {
        private volatile Instant time = START;
        public void set(Instant time) { this.time = time; }
        @Override public ZoneId getZone() { return ZoneOffset.UTC; }
        @Override public Clock withZone(ZoneId zone) { return this; }
        @Override public Instant instant() { return time; }
    }

    public static final class TestPresence implements PresenceService {
        private final Map<UUID, PresenceDto> connections = new ConcurrentHashMap<>();
        public void connect(UUID userId, Instant now) { connections.put(userId, new PresenceDto(UUID.randomUUID(), now.plusSeconds(3600))); }
        public void disconnect(UUID userId) { connections.remove(userId); }
        public void clear() { connections.clear(); }
        @Override public Optional<PresenceDto> current(UUID userId) { return Optional.ofNullable(connections.get(userId)); }
    }
}
