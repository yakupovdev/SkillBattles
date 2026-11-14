package com.skillbattles.backend.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(info = @Info(title = "SkillBattles API", version = "v1", description = "Backend infrastructure and authentication. All timestamps use UTC."))
@SecurityScheme(name = "accessBearer", type = SecuritySchemeType.HTTP, scheme = "bearer", bearerFormat = "JWT", description = "Access JWT only; valid for 15 minutes by default.")
@SecurityScheme(name = "refreshBearer", type = SecuritySchemeType.HTTP, scheme = "bearer", bearerFormat = "JWT", description = "Refresh JWT only; valid for 7 days by default. Rotated on refresh and revoked on logout.")
public class OpenApiConfig { }
