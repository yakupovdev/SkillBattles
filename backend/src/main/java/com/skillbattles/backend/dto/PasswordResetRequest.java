package com.skillbattles.backend.dto;
import lombok.*;
import jakarta.validation.constraints.*;
@Getter @Setter public class PasswordResetRequest { @NotBlank @Email @Size(max=254) private String email; }
