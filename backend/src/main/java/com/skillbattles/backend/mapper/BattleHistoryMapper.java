package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.repository.BattleHistoryProjection;
import org.mapstruct.Mapper;
import java.time.ZoneOffset;
import java.util.UUID;

@Mapper(config = CommonMapperConfig.class)
public interface BattleHistoryMapper {
    BattleHistoryItem toResponse(BattleHistoryItemDto dto);

    default BattleHistoryItemDto history(BattleHistoryProjection row, UUID userId) {
        var result = row.getResult();
        var own = result.getPlayers().stream().filter(player -> player.getId().equals(userId)).findFirst().orElseThrow();
        var opponent = result.getPlayers().stream().filter(player -> !player.getId().equals(userId)).findFirst().orElseThrow();
        BattleHistoryItemDto dto = new BattleHistoryItemDto();
        dto.setBattleId(row.getBattleId()); dto.setSubject(row.getSubject()); dto.setMode(row.getMode());
        dto.setOutcome(BattleSnapshotMapper.outcome(row.getPhase(), result.getWinnerUserId(), userId));
        dto.setReason(result.getReason()); dto.setMyScore(own.getScore()); dto.setOpponentScore(opponent.getScore());
        dto.setRatingDelta(own.getRatingDelta());
        dto.setOpponent(PublicPlayerDto.builder().id(opponent.getId()).nickname(opponent.getNickname()).build());
        dto.setCreatedAt(row.getCreatedAt().toInstant(ZoneOffset.UTC)); dto.setFinishedAt(result.getFinishedAt());
        return dto;
    }
}
