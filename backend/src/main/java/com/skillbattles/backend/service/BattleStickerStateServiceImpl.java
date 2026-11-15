package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.BattlePhase;
import com.skillbattles.backend.exception.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;

/** Bounded lazy/scheduled maintenance. No DB calls while holding protocol locks. */
@Service @RequiredArgsConstructor
public class BattleStickerStateServiceImpl implements BattleStickerStateService {
    public static final Set<String> IDS = Set.of("gg", "fire", "facepalm", "lol", "hmm", "too_slow", "ez", "wait_what", "crying");
    private static final Set<BattlePhase> ALLOWED = Set.of(BattlePhase.WAITING_READY, BattlePhase.COUNTDOWN, BattlePhase.QUESTION, BattlePhase.REVEAL);
    private final Clock clock;
    private final Object[] locks = java.util.stream.IntStream.range(0, 256).mapToObj(i -> new Object()).toArray();
    private final ConcurrentMap<UUID, UserState> users = new ConcurrentHashMap<>();
    private final Queue<UUID> userCleanup = new ConcurrentLinkedQueue<>();
    private final ConcurrentMap<UUID, Sequence> sequences = new ConcurrentHashMap<>();
    private final Queue<BattleStickerSequenceDto> sequenceCleanup = new ConcurrentLinkedQueue<>();

    @Override public BattleStickerAcceptanceDto accept(BattleDto battle, UUID sender, BattleStickerCommandDto command) {
        synchronized (lock(sender)) {
            Instant now = clock.instant();
            UserState user = users.get(sender);
            if (user != null) {
                expire(user, now);
                BattleStickerAcceptanceDto retained = user.receipts.get(command.getSubmissionId());
                if (retained != null) {
                    var receipt = retained.receipt();
                    if (!receipt.getBattleId().equals(battle.getId()) || !receipt.getStickerId().equals(command.getStickerId()))
                        throw new ConflictException("IDEMPOTENCY_CONFLICT", "Submission ID was already used with another sticker payload.");
                    return new BattleStickerAcceptanceDto(receipt, null);
                }
            }
            if (!IDS.contains(command.getStickerId())) throw new BusinessValidationException("INVALID_STICKER_ID", "Unsupported sticker.");
            if (!ALLOWED.contains(battle.getPhase())) throw new ConflictException("STICKERS_NOT_ALLOWED", "Stickers are not allowed after the battle ends.");
            if (user != null && now.isBefore(user.nextAllowedAt)) throw new StickerCooldownException(now, user.nextAllowedAt);
            UUID opponent = battle.getState().getPlayers().stream().map(BattlePlayerDto::getId).filter(id -> !id.equals(sender)).findFirst().orElseThrow();
            var receipt = new BattleStickerReceiptDto(battle.getId(), command.getSubmissionId(), sender, command.getStickerId(), now, now.plusSeconds(4));
            var data = new BattleStickerData(battle.getId(), command.getSubmissionId(), sender, command.getStickerId(), now);
            // Different users share this counter. A quiet active battle never loses its sequence.
            int[] version = new int[1];
            sequences.compute(battle.getId(), (id, previous) -> {
                Sequence sequence = previous == null ? new Sequence() : previous;
                sequence.value = Math.incrementExact(sequence.value);
                version[0] = sequence.value;
                if (!sequence.queued) { sequenceCleanup.offer(new BattleStickerSequenceDto(id, sender)); sequence.queued = true; }
                return sequence;
            });
            var event = new BattleStickerAcceptedEvent(opponent, new RealtimeEvent<>(UUID.randomUUID(), "BATTLE_STICKER", battle.getId(), version[0], now, data));
            var accepted = new BattleStickerAcceptanceDto(receipt, event);
            if (user == null) { user = new UserState(); users.put(sender, user); userCleanup.offer(sender); }
            user.nextAllowedAt = receipt.getNextAllowedAt();
            user.receipts.put(command.getSubmissionId(), accepted);
            return accepted;
        }
    }

    @Override public void cleanExpired() {
        Set<UUID> visited = new HashSet<>();
        for (int i = 0; i < 64; i++) {
            UUID id = userCleanup.poll(); if (id == null) break;
            if (!visited.add(id)) { userCleanup.offer(id); break; }
            synchronized (lock(id)) {
                UserState user = users.get(id); if (user == null) continue;
                Instant now = clock.instant(); expire(user, now);
                if (user.receipts.isEmpty() && !now.isBefore(user.nextAllowedAt)) users.remove(id);
                else userCleanup.offer(id);
            }
        }
    }
    @Override public List<BattleStickerSequenceDto> sequenceCleanupCandidates() {
        List<BattleStickerSequenceDto> result = new ArrayList<>();
        Set<UUID> visited = new HashSet<>();
        for (int i = 0; i < 32; i++) {
            var candidate = sequenceCleanup.poll(); if (candidate == null) break;
            if (!visited.add(candidate.battleId())) { sequenceCleanup.offer(candidate); break; }
            if (sequences.containsKey(candidate.battleId())) { result.add(candidate); sequenceCleanup.offer(candidate); }
        }
        return result;
    }
    @Override public void beginBattleRead(UUID battleId) {
        sequences.compute(battleId, (id, previous) -> {
            Sequence sequence = previous == null ? new Sequence() : previous;
            sequence.readers++; return sequence;
        });
    }
    @Override public void endBattleRead(UUID battleId) {
        sequences.computeIfPresent(battleId, (id, sequence) -> {
            sequence.readers--;
            return sequence.readers == 0 && (sequence.terminal || sequence.value == 0) ? null : sequence;
        });
    }
    @Override public void forgetTerminalSequence(UUID battleId) {
        sequences.computeIfPresent(battleId, (id, sequence) -> {
            sequence.terminal = true;
            return sequence.readers == 0 ? null : sequence;
        });
    }
    private Object lock(UUID user) { return locks[(user.hashCode() & Integer.MAX_VALUE) % locks.length]; }
    private void expire(UserState user, Instant now) { user.receipts.values().removeIf(r -> !now.isBefore(r.receipt().getSentAt().plusSeconds(120))); }
    private static class UserState {
        Instant nextAllowedAt;
        final Map<UUID, BattleStickerAcceptanceDto> receipts = new HashMap<>();
    }
    // A read lease prevents terminal maintenance from resetting an in-flight authorized send's sequence.
    // Fields are touched only inside ConcurrentMap.compute for this battle.
    private static class Sequence { int value; int readers; boolean queued; boolean terminal; }
}
