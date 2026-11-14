package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import org.springframework.stereotype.Service;
import java.math.*;
import java.time.Instant;
import java.util.*;

@Service
public class BattleEngineImpl implements BattleEngine {
    @Override
    public void advance(BattleDto battle, Instant now) {advance(battle,now,(b,at) -> true);}
    private void advance(BattleDto battle,Instant now,java.util.function.BiPredicate<BattleDto,Instant> startCheck) {
        while (!terminal(battle)) {
            Instant next = nextEvent(battle);
            if (next == null || next.isAfter(now)) break;
            Instant phaseDeadline = phaseDeadline(battle);
            if (next.equals(phaseDeadline)) {
                switch (battle.getPhase()) {
                    case WAITING_READY -> finish(battle, CompletionReason.READY_TIMEOUT, null, next, true);
                    case COUNTDOWN -> {
                        if(startCheck.test(battle,next)) startRound(battle,next);
                        else finish(battle,CompletionReason.QUOTA_EXHAUSTED,null,next,true);
                    }
                    case QUESTION -> reveal(battle, next);
                    case REVEAL -> {
                        if (battle.getState().getCurrentRoundIndex() == battle.getState().getRounds().size() - 1) {
                            var players = battle.getState().getPlayers();
                            UUID winner = players.get(0).getScore() == players.get(1).getScore() ? null
                                    : players.get(players.get(0).getScore() > players.get(1).getScore() ? 0 : 1).getId();
                            if(currentRound(battle).isOvertimeRound()) {
                                winner=overtimeWinner(currentRound(battle));
                                finish(battle,winner==null?CompletionReason.NORMAL:CompletionReason.OVERTIME_WIN,winner,next,false);
                            } else if(winner==null && battle.getState().getOvertimeQuestion()!=null) {
                                startOvertime(battle,next);
                            } else finish(battle, CompletionReason.NORMAL, winner, next, false);
                        } else startRound(battle, next);
                    }
                    default -> throw new IllegalStateException("Unexpected timed battle phase.");
                }
                continue;
            }
            for (BattlePlayerDto player : battle.getState().getPlayers()) {
                if (player.isConnected() && next.equals(player.getSessionExpiresAt())) {
                    disconnect(battle, player, next);
                }
            }
            for (BattlePlayerDto player : battle.getState().getPlayers()) {
                if (!player.isConnected() && next.equals(player.getReconnectDeadline())) {
                    var opponent = opponent(battle, player.getId());
                    boolean bothOffline = !opponent.isConnected();
                    boolean cancelled = !started(battle) || bothOffline;
                    finish(battle, bothOffline ? CompletionReason.BOTH_DISCONNECTED : CompletionReason.DISCONNECT,
                            cancelled ? null : opponent.getId(), next, cancelled);
                    break;
                }
            }
        }
        battle.setNextTransitionAt(terminal(battle) ? null : nextEvent(battle));
    }

    @Override
    public void synchronizePresence(BattleDto battle, Map<UUID, PresenceDto> presence, Instant now) {synchronizePresence(battle,presence,now,(b,at) -> true);}
    @Override public void synchronizePresence(BattleDto battle,Map<UUID,PresenceDto> presence,Instant now,java.util.function.BiPredicate<BattleDto,Instant> startCheck) {
        // Process observed transport changes on the same timeline as persisted battle deadlines.
        List<PresenceChange> changes = new ArrayList<>();
        for (BattlePlayerDto player : battle.getState().getPlayers()) {
            PresenceDto current = presence.get(player.getId());
            // A rapid disconnect/reconnect may complete before the asynchronous callback gets the row lock.
            // Keep the missed disconnect so a late reconnect cannot erase an already expired grace.
            if (current != null && player.isConnected() && !Objects.equals(player.getSessionId(), current.getSessionId())
                    && current.getPreviousDisconnectAt() != null && current.getPreviousDisconnectAt().isBefore(observedAt(current, now))) {
                changes.add(new PresenceChange(player, null, current.getPreviousDisconnectAt()));
            }
            changes.add(new PresenceChange(player, current, observedAt(current, now)));
        }
        changes.sort(Comparator.comparing(PresenceChange::at));
        for (PresenceChange change : changes) {
            BattlePlayerDto player = change.player();
            PresenceDto current = change.presence();
            Instant at = change.at();
            if (at.isAfter(now)) continue;
            advance(battle, at,startCheck); // Expired grace wins at equality, before applying reconnect.
            if (terminal(battle)) return;
            if (current == null || current.getSessionId() == null || current.getExpiresAt() == null || !current.getExpiresAt().isAfter(at)) {
                if (player.isConnected()) disconnect(battle, player, at);
            } else {
                if (!player.isConnected()) battle.setVersion(battle.getVersion() + 1);
                player.setConnected(true);
                player.setSessionId(current.getSessionId());
                player.setSessionExpiresAt(current.getExpiresAt());
                player.setReconnectDeadline(null);
            }
            beginCountdownIfReady(battle, at);
        }
        advance(battle, now,startCheck);
    }

    private record PresenceChange(BattlePlayerDto player, PresenceDto presence, Instant at) { }

    private Instant observedAt(PresenceDto presence, Instant fallback) {
        return presence == null || presence.getObservedAt() == null ? fallback : presence.getObservedAt();
    }

    @Override
    public void ready(BattleDto battle, UUID userId, Instant now) {
        advance(battle, now);
        if (battle.getPhase() != BattlePhase.WAITING_READY) invalidState();
        BattlePlayerDto player = player(battle, userId);
        if (!player.isConnected()) throw new ConflictException("REALTIME_CONNECTION_REQUIRED", "An authenticated live realtime subscription is required.");
        if (!player.isReady()) {
            player.setReady(true);
            battle.setVersion(battle.getVersion() + 1);
        }
        beginCountdownIfReady(battle, now);
        battle.setNextTransitionAt(nextEvent(battle));
    }

    @Override
    public AnswerReceiptDto answer(BattleDto battle, UUID userId, AnswerDto command, Instant receivedAt, Instant now) {
        player(battle, userId);
        for (BattleRoundDto round : battle.getState().getRounds()) {
            for (BattleAnswerDto accepted : round.getAnswers()) {
                if (command.getSubmissionId().equals(accepted.getSubmissionId())) {
                    if (!userId.equals(accepted.getUserId()) || !command.getRoundId().equals(accepted.getRoundId())
                            || !command.getOptionId().equals(accepted.getSelectedOptionId())) {
                        throw new ConflictException("IDEMPOTENCY_CONFLICT", "Submission ID was already used with different answer data.");
                    }
                    return receipt(battle, accepted);
                }
            }
        }
        // Entry time is authoritative. Do not expire a timely queued request just because it waited for the row lock.
        advance(battle, receivedAt);
        BattleRoundDto round = currentRound(battle);
        if (round == null || !round.getId().equals(command.getRoundId())) invalidState();
        if (round.getAnswers().stream().anyMatch(answer -> userId.equals(answer.getUserId()) && !answer.isTimedOut())) {
            throw new ConflictException("ANSWER_ALREADY_SUBMITTED", "An answer has already been submitted for this round.");
        }
        if (round.isCompleted() || !receivedAt.isBefore(round.getDeadline())) {
            throw new ConflictException("ROUND_CLOSED", "The round is closed.");
        }
        if (battle.getPhase() != BattlePhase.QUESTION || receivedAt.isBefore(round.getStartedAt()) || receivedAt.isAfter(now)) invalidState();
        if (round.getQuestion().getOptions().stream().noneMatch(option -> option.getId().equals(command.getOptionId()))) {
            throw new BusinessValidationException("INVALID_OPTION", "Option does not belong to the current question.");
        }
        BattleAnswerDto answer = new BattleAnswerDto();
        answer.setUserId(userId);
        answer.setRoundId(round.getId());
        answer.setSubmissionId(command.getSubmissionId());
        answer.setSelectedOptionId(command.getOptionId());
        answer.setAcceptedAt(receivedAt);
        answer.setCorrect(command.getOptionId().equals(round.getQuestion().getCorrectOptionId()));
        answer.setElapsedMs(receivedAt.toEpochMilli() - round.getStartedAt().toEpochMilli());
        if (answer.isCorrect() && !round.isOvertimeRound()) {
            long limitMs = limitSeconds(battle, round) * 1000L;
            long remainingMs = Math.clamp(round.getDeadline().toEpochMilli() - receivedAt.toEpochMilli(), 0L, limitMs);
            answer.setBasePoints(round.getBasePoints());
            answer.setSpeedBonus((int) (200L * remainingMs / limitMs));
            int streak=player(battle,userId).getStreak()+1;
            answer.setStreakBonus(switch(streak) {case 1 -> 0;case 2 -> 100;case 3 -> 150;case 4 -> 200;default -> 300;});
            answer.setPoints(answer.getBasePoints() + answer.getSpeedBonus() + answer.getStreakBonus());
        }
        round.getAnswers().add(answer);
        battle.setVersion(battle.getVersion() + 1);
        if (round.getAnswers().size() == 2) {
            Instant lastReceivedAt = round.getAnswers().stream().map(BattleAnswerDto::getAcceptedAt).max(Comparator.naturalOrder()).orElseThrow();
            Instant closedAt = now.isAfter(lastReceivedAt) ? now : lastReceivedAt;
            reveal(battle, closedAt.isBefore(round.getDeadline()) ? closedAt : round.getDeadline());
        }
        advance(battle, now);
        return receipt(battle, answer);
    }

    @Override
    public void surrender(BattleDto battle, UUID userId, Instant now) {
        player(battle, userId);
        advance(battle, now);
        if (!terminal(battle)) finish(battle, CompletionReason.SURRENDER,
                started(battle) ? opponent(battle, userId).getId() : null, now, !started(battle));
    }

    @Override
    public void interrupt(BattleDto battle, Instant now) {
        if (!terminal(battle)) finish(battle, CompletionReason.SERVER_INTERRUPTION, null, now, true);
    }

    private void beginCountdownIfReady(BattleDto battle, Instant now) {
        if (battle.getPhase() == BattlePhase.WAITING_READY && battle.getState().getPlayers().stream().allMatch(player -> player.isReady() && player.isConnected())) {
            battle.setPhase(BattlePhase.COUNTDOWN);
            battle.setReadyDeadline(null);
            battle.setCountdownEndsAt(now.plusSeconds(battle.getState().getCountdownSeconds()));
            battle.setVersion(battle.getVersion() + 1);
        }
    }

    private void startRound(BattleDto battle, Instant at) {
        BattleStateDto state = battle.getState();
        state.setCurrentRoundIndex(state.getCurrentRoundIndex() + 1);
        BattleRoundDto round = currentRound(battle);
        round.setStartedAt(at);
        round.setDeadline(at.plusSeconds(limitSeconds(battle, round)));
        battle.setPhase(BattlePhase.QUESTION);
        battle.setCountdownEndsAt(null);
        battle.setNextRoundStartsAt(null);
        battle.setVersion(battle.getVersion() + 1);
    }

    private void startOvertime(BattleDto battle,Instant at) {
        var state=battle.getState();
        var round=new BattleRoundDto();round.setId(UUID.randomUUID());round.setNumber(6);round.setOvertimeRound(true);
        round.setLimitSeconds(state.getOvertimeSeconds());round.setQuestion(state.getOvertimeQuestion());
        state.getRounds().add(round);
        startRound(battle,at);
    }

    private UUID overtimeWinner(BattleRoundDto round) {
        var correct=round.getAnswers().stream().filter(BattleAnswerDto::isCorrect).toList();
        if(correct.size()==1) return correct.getFirst().getUserId();
        if(correct.size()!=2 || correct.get(0).getElapsedMs().equals(correct.get(1).getElapsedMs())) return null;
        return correct.get(correct.get(0).getElapsedMs()<correct.get(1).getElapsedMs()?0:1).getUserId();
    }

    private void reveal(BattleDto battle, Instant at) {
        BattleRoundDto round = currentRound(battle);
        if (round.isCompleted()) return;
        for (BattlePlayerDto player : battle.getState().getPlayers()) {
            BattleAnswerDto answer = round.getAnswers().stream().filter(item -> player.getId().equals(item.getUserId())).findFirst().orElse(null);
            if (answer == null) {
                answer = new BattleAnswerDto();
                answer.setUserId(player.getId());
                answer.setRoundId(round.getId());
                answer.setTimedOut(true);
                round.getAnswers().add(answer);
            }
        }
        UUID overtimeWinner=round.isOvertimeRound()?overtimeWinner(round):null;
        for(BattlePlayerDto player:battle.getState().getPlayers()) {
            var answer=round.getAnswers().stream().filter(a -> a.getUserId().equals(player.getId())).findFirst().orElseThrow();
            if(player.getId().equals(overtimeWinner)) {answer.setTieBreakPoints(1);answer.setPoints(1);}
            player.setScore(Math.addExact(player.getScore(), answer.getPoints()));
            player.setCorrectCount(player.getCorrectCount() + (answer.isCorrect() ? 1 : 0));
            if(!round.isOvertimeRound()) player.setStreak(answer.isCorrect() ? player.getStreak() + 1 : 0);
        }
        round.setCompleted(true);
        round.setRevealEndsAt(at.plusSeconds(battle.getState().getRevealSeconds()));
        battle.setPhase(BattlePhase.REVEAL);
        boolean another=battle.getState().getCurrentRoundIndex()<battle.getState().getRounds().size()-1
                || (!round.isOvertimeRound() && battle.getState().getOvertimeQuestion()!=null && battle.getState().getPlayers().get(0).getScore()==battle.getState().getPlayers().get(1).getScore());
        battle.setNextRoundStartsAt(another?round.getRevealEndsAt():null);
        battle.setVersion(battle.getVersion() + 1);
    }

    private void finish(BattleDto battle, CompletionReason reason, UUID winner, Instant at, boolean cancelled) {
        if (terminal(battle)) return;
        BattleResultDataDto result = new BattleResultDataDto();
        result.setReason(reason);
        result.setWinnerUserId(winner);
        result.setFinishedAt(at);
        result.setRulesVersion(battle.getState().getRulesVersion()); result.setSeasonId(battle.getState().getSeasonId());
        result.setOvertimePlayed(battle.getState().getRounds().stream().anyMatch(BattleRoundDto::isOvertimeRound));
        List<BattlePlayerDto> players = battle.getState().getPlayers();
        boolean ranked=!cancelled && battle.getMode()==BattleMode.RANKED;
        for (int i = 0; i < players.size(); i++) {
            BattlePlayerDto player = players.get(i);
            int k=ranked?(player.getCalibrationCompletedMatches()<5?64:32):0;
            double actual=winner==null?0.5:winner.equals(player.getId())?1:0;
            int after = Math.max(0, player.getRating() + eloDelta(player.getRating(),players.get(1-i).getRating(),actual,k));
            result.getPlayers().add(new BattleResultPlayerDto(player.getId(), false, player.getNickname(), player.getScore(), player.getCorrectCount(),
                    player.getRating(), after, after - player.getRating(), k, Math.max(0,5-player.getCalibrationCompletedMatches()-(ranked?1:0)), RankCalculator.fromRating(battle.getState().getRankTiers(), player.getRating()).getCode(), RankCalculator.fromRating(battle.getState().getRankTiers(), after).getCode()));
        }
        battle.setResult(result);
        battle.setPhase(cancelled ? BattlePhase.CANCELLED : BattlePhase.FINISHED);
        battle.setReadyDeadline(null);
        battle.setCountdownEndsAt(null);
        battle.setNextRoundStartsAt(null);
        battle.setNextTransitionAt(null);
        battle.setVersion(battle.getVersion() + 1);
    }

    private int limitSeconds(BattleDto battle, BattleRoundDto round) { return round.getLimitSeconds() > 0 ? round.getLimitSeconds() : battle.getState().getLimitSeconds(); }

    static int eloDelta(int first, int second, double actual) {return eloDelta(first,second,actual,32);}
    static int eloDelta(int first, int second, double actual,int k) {
        double expected = 1.0 / (1.0 + Math.pow(10.0, ((double) second - first) / 400.0));
        return BigDecimal.valueOf(k * (actual - expected)).setScale(0, RoundingMode.HALF_UP).intValueExact();
    }

    private void disconnect(BattleDto battle, BattlePlayerDto player, Instant at) {
        player.setConnected(false);
        player.setSessionId(null);
        player.setSessionExpiresAt(null);
        player.setReconnectDeadline(at.plusSeconds(battle.getState().getReconnectGraceSeconds()));
        battle.setVersion(battle.getVersion() + 1);
    }

    private Instant nextEvent(BattleDto battle) {
        Instant next = phaseDeadline(battle);
        for (BattlePlayerDto player : battle.getState().getPlayers()) {
            Instant candidate = player.isConnected() ? player.getSessionExpiresAt() : player.getReconnectDeadline();
            if (candidate != null && (next == null || candidate.isBefore(next))) next = candidate;
        }
        return next;
    }

    private Instant phaseDeadline(BattleDto battle) {
        return switch (battle.getPhase()) {
            case WAITING_READY -> battle.getReadyDeadline();
            case COUNTDOWN -> battle.getCountdownEndsAt();
            case QUESTION -> currentRound(battle).getDeadline();
            case REVEAL -> currentRound(battle).getRevealEndsAt();
            default -> null;
        };
    }

    public static boolean terminal(BattleDto battle) { return battle.getPhase() == BattlePhase.FINISHED || battle.getPhase() == BattlePhase.CANCELLED; }
    private boolean started(BattleDto battle) { return battle.getState().getCurrentRoundIndex() >= 0; }
    private BattleRoundDto currentRound(BattleDto battle) { return started(battle) ? battle.getState().getRounds().get(battle.getState().getCurrentRoundIndex()) : null; }
    private BattlePlayerDto player(BattleDto battle, UUID id) { return battle.getState().getPlayers().stream().filter(player -> id.equals(player.getId())).findFirst().orElseThrow(() -> new NotFoundException("BATTLE_NOT_FOUND", "Battle not found.")); }
    private BattlePlayerDto opponent(BattleDto battle, UUID id) { return battle.getState().getPlayers().stream().filter(player -> !id.equals(player.getId())).findFirst().orElseThrow(); }
    private AnswerReceiptDto receipt(BattleDto battle, BattleAnswerDto answer) { return new AnswerReceiptDto(battle.getId(), answer.getRoundId(), answer.getSubmissionId(), true, answer.getAcceptedAt()); }
    private void invalidState() { throw new ConflictException("INVALID_BATTLE_STATE", "Operation is not allowed in the current battle state."); }
}
