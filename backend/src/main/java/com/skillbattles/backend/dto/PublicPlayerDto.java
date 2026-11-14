package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.time.Instant;
import java.util.UUID;

@Value @Builder(toBuilder = true)
public class PublicPlayerDto {
    UUID id;
    @com.fasterxml.jackson.annotation.JsonProperty("isPro")
    boolean pro;
    String nickname;
}
