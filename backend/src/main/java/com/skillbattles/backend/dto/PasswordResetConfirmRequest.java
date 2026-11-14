package com.skillbattles.backend.dto;
import lombok.*;
import jakarta.validation.constraints.*;
@Getter @Setter public class PasswordResetConfirmRequest {
 @NotBlank @Size(min=32,max=256) private String token;
 @NotNull @PasswordBytes @Size(min=8,max=72) private String newPassword;
}
