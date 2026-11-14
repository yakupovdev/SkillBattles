package com.skillbattles.backend.dto;
import lombok.*;import java.util.Map;
@Getter @Setter @io.swagger.v3.oas.annotations.media.Schema(requiredProperties={"object"})
public class StripeEventData {private Map<String,Object> object;}
