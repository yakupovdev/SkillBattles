package com.skillbattles.backend.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class AuthResponse {
    private String accessToken;
    private String refreshToken;
    private String tokenType;
    private long accessExpiresIn;
    private long refreshExpiresIn;
    private UserResponse user;
}
