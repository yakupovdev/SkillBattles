package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.RankTierEntity;
import org.mapstruct.Mapper;

@Mapper(config = CommonMapperConfig.class)
public interface RankMapper { RankTierDto toDto(RankTierEntity entity); RankTier toResponse(RankTierDto dto); }
