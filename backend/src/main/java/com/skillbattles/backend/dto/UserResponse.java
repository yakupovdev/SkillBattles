package com.skillbattles.backend.dto;

import lombok.Getter;
import lombok.Setter;
import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"id","isPro","email","nickname","createdAt"})
public class UserResponse {
    private UUID id;
    @com.fasterxml.jackson.annotation.JsonProperty("isPro") private boolean pro;
    private String email;
    private String nickname;
    private Instant createdAt;
}
