package com.skillbattles.backend.dto;

import jakarta.validation.constraints.*;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LoginRequest {
    @NotBlank(message = "Email is required.")
    @Email(message = "Must be a valid email address.")
    @Size(max = 254, message = "Email must not exceed 254 characters.")
    private String email;
    @NotNull(message = "Password is required.")
    @Size(min = 8, max = 72, message = "Password must contain 8 to 72 characters.")
    @PasswordBytes
    @Schema(minLength = 8, maxLength = 72, description = "8 to 72 UTF-8 bytes; never trimmed.", accessMode = Schema.AccessMode.WRITE_ONLY)
    private String password;

    public void setEmail(String email) { this.email = email == null ? null : email.trim(); }
}
