package com.skillbattles.backend.mapper;
import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.SeasonArchive;
import org.mapstruct.*;
@Mapper(config=CommonMapperConfig.class)
public interface SeasonMapper {
    SeasonDto toDto(SeasonResponse response);
    SeasonResponse toResponse(SeasonDto dto);
    SeasonArchiveDto toDto(SeasonArchive entity);
    SeasonPeakResponse toResponse(SeasonArchiveDto dto);
    @Mapping(target="id",ignore=true) @Mapping(target="createdAt",ignore=true)
    @Mapping(target="updatedAt",ignore=true) @Mapping(target="deleted",ignore=true)
    @Mapping(target="seasonStartsAt",source="season.startsAt")
    SeasonArchive create(SeasonArchiveDto dto);
}
