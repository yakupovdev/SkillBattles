package com.skillbattles.backend.dto;

import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RegisterRequest extends LoginRequest {
    @NotNull @Min(1900) private Integer birthYear;
    @NotNull @Min(1) @Max(12) private Integer birthMonth;
    @Min(1) @Max(31) private Integer birthDay;
    @NotBlank(message = "Nickname is required.")
    @Size(min = 3, max = 24, message = "Nickname must contain 3 to 24 characters.")
    @Pattern(regexp = "^[A-Za-z0-9_-]+$", message = "Nickname may contain only ASCII letters, digits, underscores and hyphens.")
    private String nickname;
}
