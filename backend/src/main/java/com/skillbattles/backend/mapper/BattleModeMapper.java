package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import org.mapstruct.Mapper;

@Mapper(config = CommonMapperConfig.class)
public interface BattleModeMapper {
    BattleModeResponse toResponse(BattleModeDto dto);
}
