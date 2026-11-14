package com.skillbattles.backend.dto;
import lombok.*;
import java.time.*;
import java.util.*;
@Data @NoArgsConstructor @AllArgsConstructor
@io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"code","name","amountCents","currency","interval","intervalCount","monthlyEquivalentCents","annualSavingsPercent","checkoutAvailable","features"})
public class SubscriptionPlan {
    private String code;
    private String name;
    private int amountCents;
    private String currency;
    private String interval;
    private int intervalCount;
    private int monthlyEquivalentCents;
    private int annualSavingsPercent;
    private boolean checkoutAvailable;
    private List<String> features;
}
