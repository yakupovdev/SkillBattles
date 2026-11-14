package com.skillbattles.backend.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class MatchCountsResponse {
    private int wins;
    private int losses;
    private int draws;
    private int played;
}
