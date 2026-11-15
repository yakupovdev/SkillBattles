package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import com.skillbattles.backend.service.RankCalculator;
import java.time.Instant;
import java.util.UUID;

/** Explicit allowlist projection: never serialize BattleDto or its JSONB state to HTTP. */
@Mapper(config = CommonMapperConfig.class, uses = QuestionImageMapper.class)
public interface BattleSnapshotMapper {
    AnswerDto toDto(AnswerRequest request);
    AnswerReceipt toResponse(AnswerReceiptDto dto);
    BattleSnapshot toResponse(BattleSnapshotDto dto);
    BattleResultResponse toResponse(BattleResultDto dto);
    QuestionViewDto question(FrozenQuestionDto dto);
    @Mapping(target = "imageUrl", source = "imageKey", qualifiedByName = "questionImageUrl")
    QuestionResponse toResponse(QuestionViewDto dto);
    AnswerViewDto answer(BattleAnswerDto dto);
    BattleResultPlayerDto copyPlayer(BattleResultPlayerDto dto);

    default BattleSnapshotDto snapshot(BattleDto battle, UUID userId, Instant now) {
        BattleSnapshotDto dto = new BattleSnapshotDto();
        dto.setId(battle.getId());
        dto.setDisciplineCode(battle.getDisciplineCode());
        dto.setMode(battle.getMode());
        dto.setPhase(battle.getPhase());
        dto.setVersion(battle.getVersion());
        dto.setServerTime(now);
        dto.setQuestionCount(battle.getState().getMainQuestionCount());
        dto.setRulesVersion(battle.getState().getRulesVersion());dto.setSeasonId(battle.getState().getSeasonId());
        dto.setOvertimePlayed(battle.getState().getRounds().stream().anyMatch(BattleRoundDto::isOvertimeRound));
        dto.setReadyDeadline(battle.getReadyDeadline());
        dto.setCountdownEndsAt(battle.getCountdownEndsAt());
        dto.setNextRoundStartsAt(battle.getNextRoundStartsAt());
        BattleRoundDto current = battle.getState().getCurrentRoundIndex() < 0 ? null
                : battle.getState().getRounds().get(battle.getState().getCurrentRoundIndex());
        dto.setPlayers(battle.getState().getPlayers().stream().map(player -> {
            PlayerViewDto view = new PlayerViewDto();
            view.setId(player.getId());
            view.setNickname(player.getNickname());
            view.setRating(player.getRating());
            view.setRankCode(RankCalculator.fromRating(battle.getState().getRankTiers(), player.getRating()).getCode());
            view.setReady(player.isReady());
            view.setConnected(player.isConnected());
            view.setReconnectDeadline(player.getReconnectDeadline());
            view.setScore(player.getScore());
            view.setCorrectCount(player.getCorrectCount());
            view.setStreak(player.getStreak());
            view.setAnsweredCurrentRound(current != null && current.getAnswers().stream()
                    .anyMatch(answer -> player.getId().equals(answer.getUserId()) && !answer.isTimedOut()));
            return view;
        }).toList());
        if (current != null) {
            RoundViewDto round = new RoundViewDto();
            round.setId(current.getId());
            round.setNumber(current.getNumber());round.setOvertimeRound(current.isOvertimeRound());
            round.setStartedAt(current.getStartedAt());
            round.setDeadline(current.getDeadline());
            round.setLimitSeconds(current.getLimitSeconds() > 0 ? current.getLimitSeconds() : battle.getState().getLimitSeconds());
            round.setQuestion(question(current.getQuestion()));
            current.getAnswers().stream().filter(answer -> userId.equals(answer.getUserId())).findFirst()
                    .ifPresent(answer -> round.setMySelectedOptionId(answer.getSelectedOptionId()));
            if (current.isCompleted()) {
                RevealViewDto reveal = new RevealViewDto();
                reveal.setCorrectOptionId(current.getQuestion().getCorrectOptionId());
                reveal.setAnswers(current.getAnswers().stream().map(this::answer).toList());
                round.setReveal(reveal);
            }
            dto.setRound(round);
        }
        dto.setResult(result(battle, userId));
        return dto;
    }

    static Outcome outcome(BattlePhase phase, UUID winner, UUID userId) {
        return phase == BattlePhase.CANCELLED ? Outcome.CANCELLED
                : winner == null ? Outcome.DRAW : userId.equals(winner) ? Outcome.WIN : Outcome.LOSS;
    }

    default BattleResultDto result(BattleDto battle, UUID userId) {
        if (battle.getResult() != null) {
            BattleResultDto result = new BattleResultDto();
            result.setBattleId(battle.getId());
            result.setRulesVersion(battle.getResult().getRulesVersion());result.setSeasonId(battle.getResult().getSeasonId());result.setOvertimePlayed(battle.getResult().isOvertimePlayed());
            result.setDisciplineCode(battle.getDisciplineCode());
            result.setMode(battle.getMode());
            result.setStatus(battle.getPhase());
            result.setReason(battle.getResult().getReason());
            result.setWinnerUserId(battle.getResult().getWinnerUserId());
            result.setFinishedAt(battle.getResult().getFinishedAt());
            result.setMyOutcome(outcome(battle.getPhase(), result.getWinnerUserId(), userId));
            result.setPlayers(battle.getResult().getPlayers().stream().map(this::copyPlayer).toList());
            return result;
        }
        return null;
    }
}
