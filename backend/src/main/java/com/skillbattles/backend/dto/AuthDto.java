package com.skillbattles.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class AuthDto {
    private final TokenPairDto tokens;
    private final UserDto user;
}
