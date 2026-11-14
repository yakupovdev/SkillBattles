package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"planCode","requestId"})
public class CheckoutRequest {
    @jakarta.validation.constraints.NotBlank @jakarta.validation.constraints.Pattern(regexp="PRO_MONTHLY|PRO_ANNUAL") private String planCode;
    @jakarta.validation.constraints.NotNull private UUID requestId;
}
