package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.RatingDto;
import com.skillbattles.backend.entity.*;
import org.mapstruct.*;
import java.util.UUID;

@Mapper(config = CommonMapperConfig.class, imports = Rank.class)
public interface RatingMapper {
    @Mapping(target = "rank", expression = "java(Rank.fromRating(rating.getRating()).getDisplayName())")
    RatingDto toDto(Rating rating);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "deleted", ignore = true)
    @Mapping(target = "rating", constant = "1000")
    Rating initial(UUID userId, Subject subject);
}
