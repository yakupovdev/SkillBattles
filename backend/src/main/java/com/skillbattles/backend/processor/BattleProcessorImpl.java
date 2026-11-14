package com.skillbattles.backend.processor;

import com.skillbattles.backend.config.BattleProperties;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.mapper.BattleSnapshotMapper;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.*;
import java.time.*;
import java.util.*;

@Component
@RequiredArgsConstructor
@Transactional
public class BattleProcessorImpl implements BattleProcessor {
    private final BattleService battleService;
    private final UserService userService;
    private final QuestionService questionService;
    private final RatingService ratingService;
    private final PresenceService presenceService;
    private final BattleEngine engine;
    private final BattleSnapshotMapper mapper;
    private final BattleProperties properties;
    private final Clock clock;
    private final ApplicationEventPublisher events;

    @Override
    public UUID create(CreateBattleDto command) {
        if (command.getFirstUserId() == null || command.getSecondUserId() == null || command.getSubject() == null
                || command.getMode() == null || command.getFirstUserId().equals(command.getSecondUserId())) {
            throw new BusinessValidationException("VALIDATION_ERROR", "Two distinct users, subject and mode are required.");
        }
        Map<UUID, UserDto> users = new HashMap<>();
        // Serialize creation for shared accounts before checking cross-column participant ownership.
        List.of(command.getFirstUserId(), command.getSecondUserId()).stream().sorted().forEach(id -> users.put(id, userService.lockActiveById(id)));
        for (UUID id : users.keySet()) {
            if (battleService.hasActiveBattle(id)) throw new ConflictException("ACTIVITY_CONFLICT", "User already participates in an active battle.");
        }
        var settings = properties.forSubject(command.getSubject());
        List<QuestionSeenDto> seen = new ArrayList<>(battleService.recentQuestionShows(command.getFirstUserId(), command.getSubject(), properties.getQuestionHistoryBattles()));
        seen.addAll(battleService.recentQuestionShows(command.getSecondUserId(), command.getSubject(), properties.getQuestionHistoryBattles()));
        var questions = questionService.selectForBattle(new QuestionSelectionDto(command.getSubject(), settings.getQuestionCount(), seen));
        Instant now = now();
        BattleDto battle = new BattleDto();
        battle.setSubject(command.getSubject());
        battle.setMode(command.getMode());
        battle.setPhase(BattlePhase.WAITING_READY);
        battle.setVersion(1);
        battle.setReadyDeadline(now.plusSeconds(properties.getReadyTimeoutSeconds()));
        BattleStateDto state = new BattleStateDto();
        state.setLimitSeconds(settings.getQuestionLimitSeconds());
        state.setCountdownSeconds(properties.getCountdownSeconds());
        state.setRevealSeconds(properties.getRevealSeconds());
        state.setReconnectGraceSeconds(properties.getReconnectGraceSeconds());
        for (UUID id : List.of(command.getFirstUserId(), command.getSecondUserId())) {
            RatingDto rating = ratingService.getByUserId(id).stream().filter(item -> item.getSubject() == command.getSubject()).findFirst().orElseThrow();
            BattlePlayerDto player = new BattlePlayerDto();
            player.setId(id);
            player.setNickname(users.get(id).getNickname());
            player.setRating(rating.getRating());
            state.getPlayers().add(player);
        }
        for (int i = 0; i < questions.size(); i++) {
            BattleRoundDto round = new BattleRoundDto();
            round.setId(UUID.randomUUID());
            round.setNumber(i + 1);
            round.setQuestion(questions.get(i));
            state.getRounds().add(round);
        }
        battle.setState(state);
        synchronize(battle, now);
        battle.setVersion(1);
        BattleDto saved = battleService.create(battle);
        publish(saved);
        return saved.getId();
    }

    @Override
    public BattleSnapshotDto snapshot(UUID battleId, UUID userId) {
        BattleDto battle = owned(battleId, userId);
        int version = battle.getVersion();
        Instant now = now();
        synchronize(battle, now);
        persist(battle, version, now);
        return mapper.snapshot(battle, userId, now);
    }

    @Override
    public BattleSnapshotDto ready(UUID battleId, UUID userId) {
        BattleDto battle = owned(battleId, userId);
        int version = battle.getVersion();
        Instant now = now();
        synchronize(battle, now);
        engine.ready(battle, userId, now);
        persist(battle, version, now);
        return mapper.snapshot(battle, userId, now);
    }

    @Override
    public AnswerReceiptDto answer(UUID battleId, UUID userId, AnswerDto command, Instant receivedAt) {
        BattleDto battle = owned(battleId, userId);
        int version = battle.getVersion();
        Instant now = now();
        synchronize(battle, receivedAt);
        AnswerReceiptDto receipt = engine.answer(battle, userId, command, receivedAt, receivedAt);
        synchronize(battle, now);
        persist(battle, version, now);
        return receipt;
    }

    @Override
    public BattleSnapshotDto surrender(UUID battleId, UUID userId) {
        BattleDto battle = owned(battleId, userId);
        int version = battle.getVersion();
        Instant now = now();
        synchronize(battle, now);
        engine.surrender(battle, userId, now);
        persist(battle, version, now);
        return mapper.snapshot(battle, userId, now);
    }

    @Override
    public BattleResultDto result(UUID battleId, UUID userId) {
        BattleSnapshotDto snapshot = snapshot(battleId, userId);
        if (snapshot.getResult() == null) throw new ConflictException("BATTLE_NOT_FINISHED", "Battle is not finished.");
        return snapshot.getResult();
    }

    @Override
    public void tick(UUID battleId) {
        BattleDto battle = battleService.lock(battleId);
        int version = battle.getVersion();
        Instant now = now();
        synchronize(battle, now);
        persist(battle, version, now);
    }

    @Override
    public void interrupt(UUID battleId) {
        BattleDto battle = battleService.lock(battleId);
        int version = battle.getVersion();
        Instant now = now();
        engine.interrupt(battle, now);
        persist(battle, version, now);
    }

    private Instant now() { return clock.instant().truncatedTo(java.time.temporal.ChronoUnit.MICROS); }

    private BattleDto owned(UUID battleId, UUID userId) {
        BattleDto battle = battleService.lock(battleId);
        if (battle.getState().getPlayers().stream().noneMatch(player -> player.getId().equals(userId))) {
            throw new NotFoundException("BATTLE_NOT_FOUND", "Battle not found.");
        }
        return battle;
    }

    private void synchronize(BattleDto battle, Instant now) {
        if (BattleEngineImpl.terminal(battle)) return;
        Map<UUID, PresenceDto> presence = new HashMap<>();
        battle.getState().getPlayers().forEach(player -> presenceService.observed(player.getId())
                .ifPresent(value -> presence.put(player.getId(), value)));
        engine.synchronizePresence(battle, presence, now);
    }

    private void persist(BattleDto battle, int previousVersion, Instant now) {
        if (BattleEngineImpl.terminal(battle) && battle.getSettledAt() == null) {
            if (battle.getPhase() == BattlePhase.FINISHED && battle.getMode() == BattleMode.RANKED) {
                ratingService.settle(battle.getResult().getPlayers().stream().map(player ->
                        new RatingUpdateDto(player.getId(), battle.getSubject(), player.getRatingBefore(), player.getRatingAfter())).toList());
            }
            battle.setSettledAt(now);
        }
        battleService.save(battle);
        if (battle.getVersion() != previousVersion) publish(battle);
    }

    private void publish(BattleDto battle) {
        BattleChangedEvent event = new BattleChangedEvent(battle.getId(), battle.getVersion(), now());
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCommit() { events.publishEvent(event); }
        });
    }
}
