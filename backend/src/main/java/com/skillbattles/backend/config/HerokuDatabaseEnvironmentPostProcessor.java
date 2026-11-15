package com.skillbattles.backend.config;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.context.config.ConfigDataEnvironmentPostProcessor;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.Profiles;

/** Maps the platform URI before datasource/Flyway auto-configuration, without logging it. */
public class HerokuDatabaseEnvironmentPostProcessor implements EnvironmentPostProcessor, Ordered {
    @Override
    public int getOrder() { return ConfigDataEnvironmentPostProcessor.ORDER + 1; }

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        if (!environment.acceptsProfiles(Profiles.of("heroku"))) return;
        environment.getPropertySources().addFirst(new MapPropertySource("herokuDatabase",
                datasourceProperties(environment.getProperty("DATABASE_URL"))));
    }

    static Map<String, Object> datasourceProperties(String value) {
        try {
            URI uri = URI.create(value == null ? "" : value);
            if (!("postgres".equals(uri.getScheme()) || "postgresql".equals(uri.getScheme()))
                    || uri.getHost() == null || uri.getRawUserInfo() == null
                    || uri.getRawPath() == null || uri.getRawPath().length() < 2
                    || uri.getRawPath().substring(1).contains("/") || uri.getFragment() != null
                    || uri.getPort() == 0 || uri.getPort() > 65535) throw new IllegalArgumentException();
            String[] credentials = uri.getRawUserInfo().split(":", 2);
            if (credentials.length != 2 || credentials[0].isEmpty() || credentials[1].isEmpty())
                throw new IllegalArgumentException();
            Map<String, String> query = new LinkedHashMap<>();
            if (uri.getRawQuery() != null) {
                for (String pair : uri.getRawQuery().split("&")) {
                    String[] entry = pair.split("=", 2);
                    String key = decode(entry[0]);
                    // Never allow credentials in the JDBC URL (also visible to Flyway logs).
                    if (!java.util.Set.of("sslmode", "connectTimeout", "socketTimeout", "applicationName")
                            .contains(key) || entry.length != 2) throw new IllegalArgumentException();
                    query.put(key, entry[1]);
                }
            }
            String ssl = decode(query.getOrDefault("sslmode", "require"));
            if (!java.util.Set.of("require", "verify-ca", "verify-full").contains(ssl))
                throw new IllegalArgumentException();
            query.put("sslmode", ssl);
            String parameters = query.entrySet().stream().map(e -> e.getKey() + "=" + e.getValue())
                    .collect(java.util.stream.Collectors.joining("&"));
            String jdbc = "jdbc:postgresql://" + uri.getHost() + ":"
                    + (uri.getPort() == -1 ? 5432 : uri.getPort()) + uri.getRawPath() + "?" + parameters;
            return Map.of("spring.datasource.url", jdbc,
                    "spring.datasource.username", decode(credentials[0]),
                    "spring.datasource.password", decode(credentials[1]));
        } catch (RuntimeException ignored) {
            // URI parsing exceptions include the input; never retain a cause containing secrets.
            throw new IllegalStateException("Heroku requires a valid PostgreSQL DATABASE_URL with TLS and credentials.");
        }
    }

    private static String decode(String value) {
        // '+' is a literal plus in URI userinfo, unlike HTML form encoding.
        return URLDecoder.decode(value.replace("+", "%2B"), StandardCharsets.UTF_8);
    }
}
