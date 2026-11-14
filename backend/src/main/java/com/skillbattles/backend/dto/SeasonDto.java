package com.skillbattles.backend.dto;
import lombok.*;
import java.time.Instant;
@Data @NoArgsConstructor @AllArgsConstructor
public class SeasonDto {
    private String id;
    private String name;
    private Instant startsAt;
    private Instant endsAt;
    private String timezone;
}
