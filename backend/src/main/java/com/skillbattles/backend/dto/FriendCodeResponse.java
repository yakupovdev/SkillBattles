package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.util.*;

@Getter @Setter
public class FriendCodeResponse {
    @Schema(requiredMode = Schema.RequiredMode.REQUIRED, minLength=12, maxLength=12, pattern = "^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{12}$")
    private String friendCode;
}
