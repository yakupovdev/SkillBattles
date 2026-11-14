package com.skillbattles.backend.config;
import org.springframework.context.annotation.Configuration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
@Configuration @EnableConfigurationProperties(BillingProperties.class)
public class BillingConfig { }
