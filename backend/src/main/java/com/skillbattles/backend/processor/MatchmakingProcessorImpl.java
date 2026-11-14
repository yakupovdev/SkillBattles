package com.skillbattles.backend.processor;

import com.skillbattles.backend.config.*;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import java.security.SecureRandom;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Component
@RequiredArgsConstructor
public class MatchmakingProcessorImpl implements MatchmakingProcessor {
    private static final String CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
    private final SecureRandom random = new SecureRandom();
    private final MatchmakingRegistryService registry;
    private final BattleService battles;
    private final BattleProcessor processor;
    private final UserService users;
    private final RatingService ratings;
    private final RatingProcessor ratingProcessor;
    private final UsageProcessor usage;
    private final SubscriptionService subscriptions;
    private final QuestionService questions;
    private final DisciplineService disciplines;
    private final MatchmakingProperties properties;
    private final Clock clock;

    @Override public QueueEntryDto search(UUID userId, String disciplineCode) {
        return registry.transact(state -> {
            Instant now = now(); refresh(state, now);
            ensureIdle(state, userId); users.getById(userId); usage.requireAvailable(userId); requireContent(disciplineCode, userId);
            int rating = ratings.getByUserId(userId).stream().filter(item -> item.getDisciplineCode().equals(disciplineCode)).findFirst().orElseThrow().getRating();
            QueueEntryDto entry = QueueEntryDto.builder().id(UUID.randomUUID()).userId(userId).rating(rating).disciplineCode(disciplineCode)
                    .status(QueueStatus.SEARCHING).createdAt(now).expiresAt(now.plusSeconds(properties.getSearchSeconds()))
                    .ratingWindow(100).version(1).build();
            state.getEntries().put(entry.getId(), entry);
            state.getActivities().put(userId, new ActivityReservationDto(ActivityType.QUEUE, entry.getId()));
            match(state, now);
            return state.getEntries().get(entry.getId());
        });
    }

    @Override public QueueEntryDto entry(UUID userId, UUID id) {
        return registry.transact(state -> { refresh(state, now()); return ownedEntry(state, userId, id); });
    }

    @Override public void cancelEntry(UUID userId, UUID id) {
        registry.transact(state -> {
            refresh(state, now());
            QueueEntryDto entry = ownedEntry(state, userId, id);
            if (entry.getStatus() == QueueStatus.MATCHED) throw matched();
            if (entry.getStatus() == QueueStatus.SEARCHING) endEntry(state, entry, QueueStatus.CANCELLED);
            return null;
        });
    }

    @Override public DuelDto createDuel(UUID userId, String disciplineCode) {
        return registry.transact(state -> {
            Instant now = now(); refresh(state, now()); ensureIdle(state, userId); requireContent(disciplineCode, userId);
            UserDto host = users.getById(userId);
            String code;
            do { code = code(); } while (codeExists(state, code)); // Retain terminal codes too: never alias a previous room.
            DuelDto duel = DuelDto.builder().id(UUID.randomUUID()).code(code).disciplineCode(disciplineCode).status(DuelStatus.WAITING)
                    .host(PublicPlayerDto.builder().id(userId).nickname(host.getNickname()).build())
                    .expiresAt(now.plusSeconds(properties.getDuelSeconds())).version(1).build();
            state.getDuels().put(duel.getId(), duel);
            state.getActivities().put(userId, new ActivityReservationDto(ActivityType.PRIVATE_DUEL, duel.getId()));
            return present(duel);
        });
    }

    @Override public DuelDto join(UUID userId, String code) {
        String normalized = code == null ? "" : code.trim().toUpperCase(Locale.ROOT);
        if (!normalized.matches("[A-Z0-9]{6}")) throw new BusinessValidationException("VALIDATION_ERROR", "Code must contain six letters or digits.");
        return registry.transact(state -> {
            refresh(state, now());
            DuelDto duel = state.getDuels().values().stream().filter(item -> item.getCode().equals(normalized)).findFirst().orElseThrow(MatchmakingProcessorImpl::duelMissing);
            if (duel.getStatus() == DuelStatus.EXPIRED) throw new GoneException("DUEL_EXPIRED", "Duel code has expired.");
            if (duel.getHost().getId().equals(userId)) throw new ConflictException("SELF_JOIN_NOT_ALLOWED", "Cannot join your own duel.");
            if (duel.getStatus() != DuelStatus.WAITING) throw new ConflictException("DUEL_NOT_JOINABLE", "Duel is no longer joinable.");
            ensureIdle(state, userId); requireContent(duel.getDisciplineCode(), userId);
            UserDto guest = users.getById(userId);
            // The staged reservation is removed while the same lock remains held through DB commit.
            state.getActivities().remove(duel.getHost().getId());
            UUID battleId = processor.create(new CreateBattleDto(duel.getHost().getId(), userId, duel.getDisciplineCode(), BattleMode.PRIVATE));
            DuelDto joined = duel.toBuilder().status(DuelStatus.MATCHED).guest(PublicPlayerDto.builder().id(userId).nickname(guest.getNickname()).build())
                    .battleId(battleId).version(duel.getVersion() + 1).build();
            state.getDuels().put(joined.getId(), joined);
            return present(joined);
        });
    }

    @Override public DuelDto duel(UUID userId, UUID id) {
        return registry.transact(state -> { refresh(state, now()); return present(ownedDuel(state, userId, id, false)); });
    }

    @Override public DuelDto present(DuelDto duel) {
        List<UUID> ids=new ArrayList<>();ids.add(duel.getHost().getId());if(duel.getGuest()!=null)ids.add(duel.getGuest().getId());
        var flags=subscriptions.proFlags(ids);
        return duel.toBuilder().host(duel.getHost().toBuilder().pro(flags.getOrDefault(duel.getHost().getId(),false)).build())
            .guest(duel.getGuest()==null?null:duel.getGuest().toBuilder().pro(flags.getOrDefault(duel.getGuest().getId(),false)).build()).build();
    }

    @Override public void cancelDuel(UUID userId, UUID id) {
        registry.transact(state -> {
            refresh(state, now()); DuelDto duel = ownedDuel(state, userId, id, true);
            if (duel.getStatus() == DuelStatus.MATCHED) throw matched();
            if (duel.getStatus() == DuelStatus.WAITING) endDuel(state, duel, DuelStatus.CANCELLED);
            return null;
        });
    }

    @Override public ActivityDto activity(UUID userId) {
        return registry.transact(state -> {
            refresh(state, now());
            Optional<UUID> battle = currentBattle(userId);
            if (battle.isPresent()) return ActivityDto.builder().type(ActivityType.BATTLE).resourceId(battle.get()).battleId(battle.get()).build();
            ActivityReservationDto reservation = state.getActivities().get(userId);
            return reservation == null ? ActivityDto.builder().type(ActivityType.NONE).build()
                    : ActivityDto.builder().type(reservation.type()).resourceId(reservation.resourceId()).build();
        });
    }

    @Override public void poll() {
        if (!registry.hasWaiting()) return;
        registry.transact(state -> { Instant now = now(); refresh(state, now); match(state, now); return null; });
    }

    private void refresh(MatchmakingStateDto state, Instant now) {
        for (QueueEntryDto entry : List.copyOf(state.getEntries().values())) {
            if (entry.getStatus() != QueueStatus.SEARCHING) continue;
            if (!entry.getExpiresAt().isAfter(now)) { endEntry(state, entry, QueueStatus.EXPIRED); continue; }
            String disciplineCode=entry.getDisciplineCode();
            var rating=ratingProcessor.prepare(entry.getUserId()).stream().filter(r -> r.getDisciplineCode().equals(disciplineCode)).findFirst().orElse(null);
            if(rating!=null && entry.getRating()!=rating.getRating()) {
                entry=entry.toBuilder().rating(rating.getRating()).version(entry.getVersion()+1).build();state.getEntries().put(entry.getId(),entry);
            }
            if (!contentAvailable(entry.getDisciplineCode(), entry.getRating())) { endEntry(state, entry, QueueStatus.CANCELLED); continue; }
            int window = window(entry, now);
            if (window != entry.getRatingWindow()) state.getEntries().put(entry.getId(), entry.toBuilder().ratingWindow(window).version(entry.getVersion() + 1).build());
        }
        for (DuelDto duel : List.copyOf(state.getDuels().values())) {
            if (duel.getStatus() == DuelStatus.WAITING && !duel.getExpiresAt().isAfter(now)) endDuel(state, duel, DuelStatus.EXPIRED);
        }
    }

    private void match(MatchmakingStateDto state, Instant now) {
        List<QueueEntryDto> ordered = state.getEntries().values().stream().filter(item -> item.getStatus() == QueueStatus.SEARCHING)
                .sorted(Comparator.comparing(QueueEntryDto::getCreatedAt).thenComparing(QueueEntryDto::getId)).toList();
        for (QueueEntryDto first : ordered) {
            if (state.getEntries().get(first.getId()).getStatus() != QueueStatus.SEARCHING) continue;
            Optional<QueueEntryDto> opponent = ordered.stream().filter(second -> !first.getUserId().equals(second.getUserId())
                    && second.getDisciplineCode().equals(first.getDisciplineCode()) && state.getEntries().get(second.getId()).getStatus() == QueueStatus.SEARCHING
                    && Math.abs((long) first.getRating() - second.getRating()) <= Math.min(window(first, now), window(second, now))).findFirst();
            if (opponent.isEmpty()) continue;
            QueueEntryDto second = opponent.get();
            state.getActivities().remove(first.getUserId()); state.getActivities().remove(second.getUserId());
            UUID battleId = processor.create(new CreateBattleDto(first.getUserId(), second.getUserId(), first.getDisciplineCode(), BattleMode.RANKED));
            for (QueueEntryDto entry : List.of(first, second)) state.getEntries().put(entry.getId(), entry.toBuilder()
                    .status(QueueStatus.MATCHED).battleId(battleId).version(entry.getVersion() + 1).build());
        }
    }

    private void ensureIdle(MatchmakingStateDto state, UUID userId) {
        if (state.getActivities().containsKey(userId) || currentBattle(userId).isPresent())
            throw new ConflictException("ACTIVITY_CONFLICT", "User already has an active queue, duel or battle.");
    }
    private Optional<UUID> currentBattle(UUID userId) {
        for (UUID id : battles.activeIdsForUser(userId)) {
            var snapshot = processor.snapshot(id, userId);
            if (snapshot.getPhase() != BattlePhase.FINISHED && snapshot.getPhase() != BattlePhase.CANCELLED) return Optional.of(id);
        }
        return Optional.empty();
    }
    private int window(QueueEntryDto entry, Instant now) {
        long seconds = Duration.between(entry.getCreatedAt(), now).getSeconds();
        return seconds < 15 ? 100 : seconds < 30 ? 200 : 400;
    }
    private void requireContent(String disciplineCode, UUID userId) {
        disciplines.requireActive(disciplineCode);
        ratingProcessor.prepare(userId);
        int rating = ratings.getByUserId(userId).stream().filter(r -> r.getDisciplineCode().equals(disciplineCode)).findFirst().orElseThrow().getRating();
        if (!contentAvailable(disciplineCode, rating)) throw new ConflictException("CONTENT_UNAVAILABLE", "Not enough suitable questions for a full battle.");
    }
    private boolean contentAvailable(String code, int rating) {
        DisciplineDto discipline;
        try { discipline = disciplines.get(code); } catch (ConflictException ex) { return false; }
        if (!discipline.isActive()) return false;
        Map<Difficulty, Long> counts = new EnumMap<>(Difficulty.class);
        for (var difficulty : Difficulty.values()) counts.put(difficulty, questions.countAvailable(code, difficulty));
        return discipline.getSchedules().stream().anyMatch(s -> s.getMinRating() <= rating && DisciplineContentPolicy.available(s, counts));
    }
    private void endEntry(MatchmakingStateDto state, QueueEntryDto entry, QueueStatus status) {
        state.getEntries().put(entry.getId(), entry.toBuilder().status(status).version(entry.getVersion() + 1).build());
        state.getActivities().remove(entry.getUserId(), new ActivityReservationDto(ActivityType.QUEUE, entry.getId()));
    }
    private void endDuel(MatchmakingStateDto state, DuelDto duel, DuelStatus status) {
        state.getDuels().put(duel.getId(), duel.toBuilder().status(status).version(duel.getVersion() + 1).build());
        state.getActivities().remove(duel.getHost().getId(), new ActivityReservationDto(ActivityType.PRIVATE_DUEL, duel.getId()));
    }
    private QueueEntryDto ownedEntry(MatchmakingStateDto state, UUID userId, UUID id) {
        QueueEntryDto entry = state.getEntries().get(id);
        if (entry == null || !entry.getUserId().equals(userId)) throw new NotFoundException("QUEUE_ENTRY_NOT_FOUND", "Queue entry not found.");
        return entry;
    }
    private DuelDto ownedDuel(MatchmakingStateDto state, UUID userId, UUID id, boolean hostOnly) {
        DuelDto duel = state.getDuels().get(id);
        if (duel == null || !duel.getHost().getId().equals(userId) && (hostOnly || duel.getGuest() == null || !duel.getGuest().getId().equals(userId))) throw duelMissing();
        return duel;
    }
    private String code() {
        StringBuilder result = new StringBuilder(6);
        for (int i = 0; i < 6; i++) result.append(CODE_ALPHABET.charAt(random.nextInt(CODE_ALPHABET.length())));
        return result.toString();
    }
    private boolean codeExists(MatchmakingStateDto state, String code) { return state.getDuels().values().stream().anyMatch(duel -> duel.getCode().equals(code)); }
    private Instant now() { return clock.instant().truncatedTo(ChronoUnit.MICROS); }
    private static ConflictException matched() { return new ConflictException("MATCH_ALREADY_FOUND", "A battle has already been created. Recover current activity."); }
    private static NotFoundException duelMissing() { return new NotFoundException("DUEL_NOT_FOUND", "Duel not found."); }
}
