package com.skillbattles.backend.dto;

import java.util.List;

public class BattleHistoryPage extends PageResponse<BattleHistoryItem> {
    @lombok.Getter
    @io.swagger.v3.oas.annotations.media.Schema(requiredMode=io.swagger.v3.oas.annotations.media.Schema.RequiredMode.REQUIRED,nullable=true)
    private final Integer historyLimit;
    public BattleHistoryPage(List<BattleHistoryItem> data,PaginationDto pagination,Integer historyLimit) {super(data,pagination);this.historyLimit=historyLimit;}
}
