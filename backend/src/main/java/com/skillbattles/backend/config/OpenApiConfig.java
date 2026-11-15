package com.skillbattles.backend.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(info = @Info(title = "SkillBattles API", version = "0.3.0", description = "SkillBattles v0.3: 58 product REST operations plus 2 public illustration GET/HEAD operations, server-side age screening, profile and password reset, full basic statistics, Pro analytics, seasonal leaderboard, private rematches with recoverable incoming invitations and question reports, persistent friends, basic friend profiles and invitations to existing private rooms and ephemeral opponent-only battle stickers. Stripe is TEST-only; live provider webhook round-trip verification is a separate environment check. Access tokens retain their expiry after password changes. All timestamps use UTC; business dates use America/New_York."))
@SecurityScheme(name = "accessBearer", type = SecuritySchemeType.HTTP, scheme = "bearer", bearerFormat = "JWT", description = "Access JWT only; valid for 15 minutes by default.")
@SecurityScheme(name = "refreshBearer", type = SecuritySchemeType.HTTP, scheme = "bearer", bearerFormat = "JWT", description = "Refresh JWT only; valid for 7 days by default. Rotated on refresh and revoked on logout.")
@SecurityScheme(name="stripeSignature",type=SecuritySchemeType.APIKEY,in=io.swagger.v3.oas.annotations.enums.SecuritySchemeIn.HEADER,paramName="Stripe-Signature")
public class OpenApiConfig { }
