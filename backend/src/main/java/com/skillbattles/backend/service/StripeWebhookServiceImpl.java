package com.skillbattles.backend.service;
import com.skillbattles.backend.config.BillingProperties;
import com.skillbattles.backend.exception.*;
import com.fasterxml.jackson.databind.*;
import com.stripe.net.Webhook;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.Clock;
import java.nio.charset.StandardCharsets;
@Service @RequiredArgsConstructor
public class StripeWebhookServiceImpl implements StripeWebhookService {
    private final BillingProperties properties;private final ObjectMapper json;private final Clock clock;
    @Override public JsonNode verify(byte[] raw,String signature) {
        if(properties.getWebhookSecret().isBlank()||!"TEST".equals(properties.getMode())) throw new BillingUnavailableException();
        String body=new String(raw,StandardCharsets.UTF_8);
        try {Webhook.constructEvent(body,signature,properties.getWebhookSecret(),300,clock);} catch(Exception ex) {throw new BusinessValidationException("INVALID_WEBHOOK_SIGNATURE","Invalid webhook signature.");}
        try {
            var e=json.readTree(raw);
            if(!"event".equals(e.path("object").asText()) || !e.path("id").asText().startsWith("evt_") || !e.path("type").isTextual() || e.path("type").asText().isBlank() || !e.path("created").isIntegralNumber() || e.path("created").asLong()<=0
                || !e.path("livemode").isBoolean() || e.path("livemode").asBoolean() || !e.path("data").path("object").isObject() || e.path("data").path("object").path("livemode").asBoolean()) throw new IllegalArgumentException();
            return e;
        } catch(Exception ex) {throw new BusinessValidationException("INVALID_WEBHOOK_EVENT","Invalid test webhook event.");}
    }
}
