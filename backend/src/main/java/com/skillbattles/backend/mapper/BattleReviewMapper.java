package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import org.mapstruct.*;

@Mapper(config = CommonMapperConfig.class, uses = BattleSnapshotMapper.class)
public interface BattleReviewMapper {
    BattleReview toResponse(BattleReviewDto dto);
    @Mapping(target = "roundId", source = "id")
    ReviewRoundDto round(BattleRoundDto dto);
    ReviewQuestionDto question(FrozenQuestionDto dto);

    default BattleReviewDto review(BattleDto battle) {
        BattleReviewDto dto = new BattleReviewDto();
        dto.setBattleId(battle.getId()); dto.setSubject(battle.getSubject()); dto.setMode(battle.getMode());
        dto.setRounds(battle.getState().getRounds().stream().filter(item -> item.getStartedAt() != null).map(this::round).toList());
        return dto;
    }
}
