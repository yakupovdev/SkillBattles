package com.skillbattles.backend.dto;
import lombok.*;
import jakarta.validation.constraints.*;
@Getter @Setter
public class UpdateProfileRequest {
 @Size(min=3,max=24) @Pattern(regexp="^[A-Za-z0-9_-]+$") @com.fasterxml.jackson.annotation.JsonSetter(nulls=com.fasterxml.jackson.annotation.Nulls.FAIL) private String nickname;
 @PasswordBytes(min=1,message="Current password must contain 1 to 72 UTF-8 bytes.") @Size(min=1,max=72) @com.fasterxml.jackson.annotation.JsonSetter(nulls=com.fasterxml.jackson.annotation.Nulls.FAIL) private String currentPassword;
 @PasswordBytes @Size(min=8,max=72) @com.fasterxml.jackson.annotation.JsonSetter(nulls=com.fasterxml.jackson.annotation.Nulls.FAIL) private String newPassword;
}
