package com.skillbattles.backend.mapper;
import com.skillbattles.backend.config.CommonMapperConfig;import com.skillbattles.backend.dto.*;import com.skillbattles.backend.entity.QuestionReport;import org.mapstruct.*;
@Mapper(config=CommonMapperConfig.class,uses=UserMapper.class) public interface ReportMapper {
 @Mapping(target="created",ignore=true) ReportDto toDto(QuestionReport entity);
 @Mapping(target="status",constant="RECEIVED") ReportResponse toResponse(ReportDto dto);
}
