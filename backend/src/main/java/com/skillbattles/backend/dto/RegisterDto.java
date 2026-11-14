package com.skillbattles.backend.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RegisterDto {
    private Integer birthYear;
    private Integer birthMonth;
    private Integer birthDay;
    private String email;
    private String password;
    private String nickname;
}
