package com.skillbattles.backend.dto;

import java.util.List;

public class BattleHistoryPage extends PageResponse<BattleHistoryItem> {
    public BattleHistoryPage(List<BattleHistoryItem> data, PaginationDto pagination) { super(data, pagination); }
}
