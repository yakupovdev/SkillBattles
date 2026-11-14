package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.Battle;
import org.mapstruct.*;
import org.mapstruct.control.DeepClone;

@Mapper(config = CommonMapperConfig.class, mappingControl = DeepClone.class)
public interface BattleMapper {
    BattleDto toDto(Battle battle);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "deleted", ignore = true)
    @Mapping(target = "firstUserId", expression = "java(dto.getState().getPlayers().get(0).getId())")
    @Mapping(target = "secondUserId", expression = "java(dto.getState().getPlayers().get(1).getId())")
    @Mapping(target = "winnerUserId", expression = "java(dto.getResult() == null ? null : dto.getResult().getWinnerUserId())")
    Battle create(BattleDto dto);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "deleted", ignore = true)
    @Mapping(target = "firstUserId", ignore = true)
    @Mapping(target = "secondUserId", ignore = true)
    @Mapping(target = "winnerUserId", expression = "java(dto.getResult() == null ? null : dto.getResult().getWinnerUserId())")
    void update(BattleDto dto, @MappingTarget Battle entity);
}
