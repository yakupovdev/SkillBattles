package com.skillbattles.backend.config;
import lombok.*;
import org.springframework.boot.context.properties.ConfigurationProperties;
@Getter @Setter @ConfigurationProperties(prefix="app.billing")
public class BillingProperties {
    private String mode="TEST";
    private String secretKey="";
    private String webhookSecret="";
    private String monthlyPrice="";
    private String annualPrice="";
    private String successUrl="";
    private String cancelUrl="";
    private String portalReturnUrl="";
}
