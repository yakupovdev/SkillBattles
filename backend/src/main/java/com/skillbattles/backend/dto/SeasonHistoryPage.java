package com.skillbattles.backend.dto;
import lombok.*;
import java.util.List;
@Getter @AllArgsConstructor
public class SeasonHistoryPage {
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private final List<SeasonPeakResponse> data;
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode = io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED)
    private final PaginationDto pagination;
}
