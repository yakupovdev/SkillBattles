package com.skillbattles.backend.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(info = @Info(title = "SkillBattles API — v0.3 stage C", version = "0.3.0-stage-c", description = "Intermediate v0.3 with scoring, combat streak, overtime, individual calibration and ET seasons. Stripe TEST subscriptions, entitlements, quota, history/answer filtering and daily/weekly streaks are implemented. Age screening, advanced analytics and stages D/E are not implemented. This is not the completed v0.3 target contract. All timestamps use UTC."))
@SecurityScheme(name = "accessBearer", type = SecuritySchemeType.HTTP, scheme = "bearer", bearerFormat = "JWT", description = "Access JWT only; valid for 15 minutes by default.")
@SecurityScheme(name = "refreshBearer", type = SecuritySchemeType.HTTP, scheme = "bearer", bearerFormat = "JWT", description = "Refresh JWT only; valid for 7 days by default. Rotated on refresh and revoked on logout.")
@SecurityScheme(name="stripeSignature",type=SecuritySchemeType.APIKEY,in=io.swagger.v3.oas.annotations.enums.SecuritySchemeIn.HEADER,paramName="Stripe-Signature")
public class OpenApiConfig { }
