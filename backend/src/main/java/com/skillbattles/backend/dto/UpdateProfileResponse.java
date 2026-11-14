package com.skillbattles.backend.dto;
import lombok.*;
@Value
public class UpdateProfileResponse { UserResponse user; boolean passwordChanged; boolean reauthenticationRequired; }
