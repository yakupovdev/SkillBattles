package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.Discipline;
import org.mapstruct.*;
import org.mapstruct.control.DeepClone;

@Mapper(config = CommonMapperConfig.class, mappingControl = DeepClone.class)
public interface DisciplineMapper { DisciplineDto toDto(Discipline entity); }
