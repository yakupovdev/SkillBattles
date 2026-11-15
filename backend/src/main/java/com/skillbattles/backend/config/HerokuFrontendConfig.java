package com.skillbattles.backend.config;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.boot.web.server.MimeMappings;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.boot.web.servlet.server.ConfigurableServletWebServerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.header.writers.StaticHeadersWriter;

@Configuration
@Profile("heroku")
@org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication(
        type = org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication.Type.SERVLET)
public class HerokuFrontendConfig {
    @Bean
    public WebServerFactoryCustomizer<ConfigurableServletWebServerFactory> frontendMimeTypes() {
        return factory -> {
            MimeMappings mappings = new MimeMappings(MimeMappings.DEFAULT);
            mappings.add("wasm", "application/wasm");
            mappings.add("mjs", "application/javascript");
            factory.setMimeMappings(mappings);
        };
    }

    @Bean
    @Order(0)
    public SecurityFilterChain frontendChain(HttpSecurity http) throws Exception {
        return http.securityMatcher(HerokuFrontendConfig::isFrontendRequest)
                .csrf(AbstractHttpConfigurer::disable)
                .requestCache(AbstractHttpConfigurer::disable)
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .headers(h -> h.addHeaderWriter(new StaticHeadersWriter("Cross-Origin-Opener-Policy", "same-origin"))
                        .addHeaderWriter(new StaticHeadersWriter("Cross-Origin-Embedder-Policy", "require-corp")))
                .authorizeHttpRequests(a -> a.anyRequest().permitAll()).build();
    }

    static boolean isFrontendRequest(HttpServletRequest request) {
        if (!("GET".equals(request.getMethod()) || "HEAD".equals(request.getMethod()))) return false;
        String path = request.getServletPath();
        if (path.isEmpty()) path = request.getRequestURI().substring(request.getContextPath().length());
        for (String reserved : new String[]{"/api", "/ws", "/media", "/swagger-ui", "/v3", "/error"}) {
            if (path.equals(reserved) || path.startsWith(reserved + "/")
                    || path.startsWith(reserved + ".")) return false;
        }
        return true;
    }
}
