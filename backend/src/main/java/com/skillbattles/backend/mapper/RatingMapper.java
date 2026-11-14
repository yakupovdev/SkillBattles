package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.RatingDto;
import com.skillbattles.backend.entity.*;
import org.mapstruct.*;
import java.util.UUID;

@Mapper(config = CommonMapperConfig.class)
public interface RatingMapper {
    @Mapping(target = "rankCode", ignore = true)
    @Mapping(target = "rankName", ignore = true)
    @Mapping(target = "seasonRolloverPending", ignore = true)
    RatingDto toDto(Rating rating);

}
