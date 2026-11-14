package com.skillbattles.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import org.springframework.data.domain.Page;
import java.util.List;
import java.util.function.Function;

@Getter
@AllArgsConstructor
public class PageResponse<T> {
    private final List<T> data;
    private final PaginationDto pagination;

    public static <S, T> PageResponse<T> from(Page<S> page, Function<S, T> mapper) {
        return new PageResponse<>(page.getContent().stream().map(mapper).toList(),
                new PaginationDto(page.getNumber(), page.getSize(), page.getTotalElements(), page.getTotalPages()));
    }
}
