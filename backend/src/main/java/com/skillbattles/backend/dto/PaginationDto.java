package com.skillbattles.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import io.swagger.v3.oas.annotations.media.Schema;

@Getter
@AllArgsConstructor
public class PaginationDto {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, description = "Zero-based page index", minimum = "0", defaultValue = "0")
    private final int page;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, description = "Page size", minimum = "1", maximum = "100", defaultValue = "20")
    private final int size;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private final long totalElements;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private final int totalPages;
}
