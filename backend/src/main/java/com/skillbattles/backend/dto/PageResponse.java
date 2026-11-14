package com.skillbattles.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import io.swagger.v3.oas.annotations.media.Schema;
import org.springframework.data.domain.Page;
import java.util.List;
import java.util.function.Function;

@Getter
@AllArgsConstructor
public class PageResponse<T> {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private final List<T> data;
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED)
    private final PaginationDto pagination;

    public static <S, T> PageResponse<T> from(Page<S> page, Function<S, T> mapper) {
        return new PageResponse<>(page.getContent().stream().map(mapper).toList(),
                new PaginationDto(page.getNumber(), page.getSize(), page.getTotalElements(), page.getTotalPages()));
    }
}
