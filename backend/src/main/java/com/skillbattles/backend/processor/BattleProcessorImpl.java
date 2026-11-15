package com.skillbattles.backend.processor;

import com.skillbattles.backend.config.BattleProperties;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.mapper.BattleSnapshotMapper;
import com.skillbattles.backend.mapper.BattleReviewMapper;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Propagation;
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
    private final MatchmakingRegistryService registry;
    private final BattleReviewMapper reviewMapper;
    private final DisciplineService disciplines;
    private final RankService ranks;
    private final RatingProcessor ratingProcessor;
    private final SeasonService seasons;
    private final UsageProcessor usage;
    private final BattleAccessProcessor access;

    @Override
    @Transactional(propagation = Propagation.SUPPORTS)
    public UUID create(CreateBattleDto command) {
        return registry.transact(state -> {
            if (state.getActivities().containsKey(command.getFirstUserId()) || state.getActivities().containsKey(command.getSecondUserId()))
                throw new ConflictException("ACTIVITY_CONFLICT", "User already has a waiting queue or duel.");
            return createLocked(command);
        });
    }

    private UUID createLocked(CreateBattleDto command) {
        if (command.getFirstUserId() == null || command.getSecondUserId() == null || command.getDisciplineCode() == null
                || command.getMode() == null || command.getFirstUserId().equals(command.getSecondUserId())) {
            throw new BusinessValidationException("VALIDATION_ERROR", "Two distinct users, disciplineCode and mode are required.");
        }
        Map<UUID, UserDto> users = new HashMap<>();
        // Serialize creation for shared accounts before checking cross-column participant ownership.
        List.of(command.getFirstUserId(), command.getSecondUserId()).stream().sorted(Comparator.comparing(UUID::toString)).forEach(id -> users.put(id, userService.lockActiveById(id)));
        for (UUID id : users.keySet()) {
            if (battleService.hasActiveBattle(id)) throw new ConflictException("ACTIVITY_CONFLICT", "User already participates in an active battle.");
        }
        var settings = disciplines.requireActive(command.getDisciplineCode());
        if (command.getFormat() != settings.getFormat()) throw new BusinessValidationException("VALIDATION_ERROR", "Unsupported battle format.");
        // Lock both accounts' ratings before taking one season cut for the pair.
        // A quarter boundary between preparing the two players must not mix seasons.
        users.keySet().stream().sorted(Comparator.comparing(UUID::toString)).forEach(id -> {ratingService.initialize(id);ratingService.lockForUser(id);});
        var pairSeason=seasons.current();
        Map<UUID, RatingDto> playerRatings = new HashMap<>();
        for (UUID id : users.keySet()) {
            playerRatings.put(id, ratingProcessor.prepare(id,pairSeason).stream().filter(r -> r.getDisciplineCode().equals(command.getDisciplineCode())).findFirst().orElseThrow());
        }
        int lowerRating = playerRatings.values().stream().mapToInt(RatingDto::getRating).min().orElseThrow();
        var schedule = DisciplineContentPolicy.schedule(settings, lowerRating);
        List<QuestionSeenDto> seen = new ArrayList<>(battleService.recentQuestionShows(command.getFirstUserId(), command.getDisciplineCode(), properties.getQuestionHistoryBattles()));
        seen.addAll(battleService.recentQuestionShows(command.getSecondUserId(), command.getDisciplineCode(), properties.getQuestionHistoryBattles()));
        Map<Difficulty, Integer> needed = new EnumMap<>(Difficulty.class);
        schedule.getRoundDifficulties().forEach(d -> needed.merge(d, 1, Integer::sum));
        needed.merge(Difficulty.MEDIUM, 1, Integer::sum);
        Map<Difficulty, ArrayDeque<FrozenQuestionDto>> pool = new EnumMap<>(Difficulty.class);
        for (var entry : needed.entrySet()) pool.put(entry.getKey(), new ArrayDeque<>(questionService.selectForBattle(
                new QuestionSelectionDto(command.getDisciplineCode(), entry.getValue(), seen, entry.getKey()))));
        Instant now = now();
        BattleDto battle = new BattleDto();
        battle.setDisciplineCode(command.getDisciplineCode());
        battle.setMode(command.getMode());
        battle.setPhase(BattlePhase.WAITING_READY);
        battle.setVersion(1);
        battle.setReadyDeadline(now.plusSeconds(properties.getReadyTimeoutSeconds()));
        BattleStateDto state = new BattleStateDto();
        state.setLimitSeconds(disciplines.limitSeconds(settings, Difficulty.MEDIUM));
        state.setRankTiers(ranks.tiers());
        state.setMainQuestionCount(settings.getQuestionCount());
        state.setSeasonId(command.getMode()==BattleMode.RANKED?pairSeason.getId():null);
        state.setOvertimeSeconds(settings.getOvertimeSeconds());
        state.setCountdownSeconds(properties.getCountdownSeconds());
        state.setRevealSeconds(properties.getRevealSeconds());
        state.setReconnectGraceSeconds(properties.getReconnectGraceSeconds());
        for (UUID id : List.of(command.getFirstUserId(), command.getSecondUserId())) {
            RatingDto rating = playerRatings.get(id);
            BattlePlayerDto player = new BattlePlayerDto();
            player.setId(id);
            player.setNickname(users.get(id).getNickname());
            player.setRating(rating.getRating());
            player.setCalibrationCompletedMatches(rating.getCalibrationCompletedMatches());
            state.getPlayers().add(player);
        }
        for (int i = 0; i < schedule.getRoundDifficulties().size(); i++) {
            Difficulty difficulty = schedule.getRoundDifficulties().get(i);
            BattleRoundDto round = new BattleRoundDto();
            round.setId(UUID.randomUUID());
            round.setNumber(i + 1);
            round.setQuestion(pool.get(difficulty).removeFirst());
            round.setLimitSeconds(disciplines.limitSeconds(settings, difficulty));
            round.setBasePoints(settings.getTimings().stream().filter(t -> t.getDifficulty() == difficulty).findFirst().orElseThrow().getBasePoints());
            state.getRounds().add(round);
        }
        state.setOvertimeQuestion(pool.get(Difficulty.MEDIUM).removeFirst());
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
        return access.snapshot(battle, userId, now);
    }

    @Override
    public BattleSnapshotDto ready(UUID battleId, UUID userId) {
        BattleDto battle = owned(battleId, userId);
        int version = battle.getVersion();
        Instant now = now();
        synchronize(battle, now);
        engine.ready(battle, userId, now);
        persist(battle, version, now);
        return access.snapshot(battle, userId, now);
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
        return access.snapshot(battle, userId, now);
    }

    @Override
    @Transactional(readOnly = true)
    public BattleResultDto result(UUID battleId, UUID userId) {
        return access.result(terminalRead(battleId, userId), userId);
    }

    @Override
    @Transactional(readOnly = true)
    public BattleReviewDto review(UUID battleId, UUID userId) {
        return access.review(terminalRead(battleId, userId),userId);
    }

    @Override @Transactional(readOnly=true) public BattleReviewDto review(UUID battleId,UUID userId,boolean mistakesOnly){
        var dto=review(battleId,userId);
        if(mistakesOnly){
            if(!dto.getAnswerAccess().isCanViewCorrectAnswer())throw new ProRequiredException();
            dto.setRounds(dto.getRounds().stream().filter(r->r.getAnswers().stream().noneMatch(a->a.getUserId().equals(userId)&&a.isCorrect())).toList());
        }
        dto.setMistakesOnly(mistakesOnly);return dto;
    }
    private BattleDto terminalRead(UUID battleId, UUID userId) {
        BattleDto battle = battleService.getForParticipant(battleId, userId);
        if (!BattleEngineImpl.terminal(battle)) throw new ConflictException("BATTLE_NOT_FINISHED", "Battle is not finished.");
        access.require(battle,userId);return battle;
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
        access.require(battle,userId);return battle;
    }

    private void synchronize(BattleDto battle, Instant now) {
        if (BattleEngineImpl.terminal(battle)) return;
        Map<UUID, PresenceDto> presence = new HashMap<>();
        battle.getState().getPlayers().forEach(player -> presenceService.observed(player.getId())
                .ifPresent(value -> presence.put(player.getId(), value)));
        engine.synchronizePresence(battle, presence, now,usage::start);
    }

    private void persist(BattleDto battle, int previousVersion, Instant now) {
        boolean newlySettled=BattleEngineImpl.terminal(battle) && battle.getSettledAt() == null;
        if (newlySettled) {
            usage.finish(battle);
            if (battle.getPhase() == BattlePhase.FINISHED && battle.getMode() == BattleMode.RANKED) {
                ratingService.settle(battle.getResult().getPlayers().stream().map(player ->
                        new RatingUpdateDto(player.getId(), battle.getDisciplineCode(), player.getRatingBefore(), player.getRatingAfter(),battle.getState().getSeasonId(),
                                battle.getState().getPlayers().stream().filter(p -> p.getId().equals(player.getId())).findFirst().orElseThrow().getCalibrationCompletedMatches())).toList());
            }
            battle.setSettledAt(now);
        }
        battleService.save(battle);
        if(newlySettled) battle.getState().getPlayers().stream().map(BattlePlayerDto::getId).sorted(Comparator.comparing(UUID::toString)).forEach(ratingProcessor::prepare);
        if (battle.getVersion() != previousVersion) publish(battle);
    }

    private void publish(BattleDto battle) {
        BattleChangedEvent event = new BattleChangedEvent(battle.getId(), battle.getVersion(), now());
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCommit() { events.publishEvent(event); }
        });
    }
}
