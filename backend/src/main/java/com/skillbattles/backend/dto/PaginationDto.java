package com.skillbattles.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import io.swagger.v3.oas.annotations.media.Schema;

@Getter
@AllArgsConstructor
public class PaginationDto {
    @Schema(description = "Zero-based page index", minimum = "0", defaultValue = "0")
    private final int page;
    @Schema(description = "Page size", minimum = "1", maximum = "100", defaultValue = "20")
    private final int size;
    private final long totalElements;
    private final int totalPages;
}
