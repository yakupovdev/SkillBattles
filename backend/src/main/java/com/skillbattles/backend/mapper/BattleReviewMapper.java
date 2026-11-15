package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import org.mapstruct.*;

@Mapper(config = CommonMapperConfig.class, uses = {BattleSnapshotMapper.class, QuestionImageMapper.class})
public interface BattleReviewMapper {
    BattleReview toResponse(BattleReviewDto dto);
    @Mapping(target = "roundId", source = "id")
    ReviewRoundDto round(BattleRoundDto dto);
    ReviewQuestionDto question(FrozenQuestionDto dto);
    @Mapping(target = "imageUrl", source = "imageKey", qualifiedByName = "questionImageUrl")
    ReviewQuestionResponse toResponse(ReviewQuestionDto dto);

    default BattleReviewDto review(BattleDto battle) {
        BattleReviewDto dto = new BattleReviewDto();
        dto.setRulesVersion(battle.getState().getRulesVersion());
        dto.setBattleId(battle.getId()); dto.setDisciplineCode(battle.getDisciplineCode()); dto.setMode(battle.getMode());
        dto.setRounds(battle.getState().getRounds().stream().filter(item -> item.getStartedAt() != null).map(this::round).toList());
        return dto;
    }
}
