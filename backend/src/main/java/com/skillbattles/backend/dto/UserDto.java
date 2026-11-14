package com.skillbattles.backend.dto;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
public class UserDto {
    private UUID id;
    @com.fasterxml.jackson.annotation.JsonProperty("isPro") private boolean pro;
    private String email;
    private String nickname;
    private LocalDateTime createdAt;
}
