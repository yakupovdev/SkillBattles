package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.RefreshTokenDto;
import com.skillbattles.backend.entity.RefreshToken;
import org.mapstruct.*;

@Mapper(config = CommonMapperConfig.class)
public interface RefreshTokenMapper {
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "deleted", ignore = true)
    @Mapping(target = "revokedAt", ignore = true)
    RefreshToken toEntity(RefreshTokenDto dto);
}
