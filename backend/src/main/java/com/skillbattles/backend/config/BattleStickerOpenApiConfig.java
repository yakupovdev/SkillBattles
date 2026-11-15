package com.skillbattles.backend.config;

import com.skillbattles.backend.dto.BattleStickerData;
import com.skillbattles.backend.service.BattleStickerStateServiceImpl;
import io.swagger.v3.core.converter.ModelConverters;
import io.swagger.v3.oas.models.media.*;
import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.context.annotation.*;
import java.math.BigDecimal;
import java.util.*;

@Configuration
public class BattleStickerOpenApiConfig {
    @Bean OpenApiCustomizer battleStickerEvents() {
        return api -> {
            ModelConverters.getInstance().read(BattleStickerData.class).forEach(api.getComponents()::addSchemas);
            var envelope = new ObjectSchema().additionalProperties(false);
            envelope.addProperty("eventId", new UUIDSchema());
            envelope.addProperty("type", new StringSchema()._enum(List.of("BATTLE_STICKER")));
            envelope.addProperty("resourceId", new UUIDSchema().description("Equals data.battleId."));
            envelope.addProperty("version", new IntegerSchema().format("int32").minimum(BigDecimal.ONE).description("Separate per-battle sticker sequence, never battle.version. Gaps are expected; restart resets this counter."));
            envelope.addProperty("occurredAt", new DateTimeSchema().description("Equals data.sentAt."));
            envelope.addProperty("data", new Schema<>().$ref("#/components/schemas/BattleStickerData"));
            envelope.setRequired(List.of("eventId", "type", "resourceId", "version", "occurredAt", "data"));
            api.getComponents().addSchemas("BattleStickerEnvelope", envelope);
            api.getComponents().addSchemas("StickerId", new StringSchema()._enum(BattleStickerStateServiceImpl.IDS.stream().sorted().toList()));
            api.addExtension("x-battle-stickers", Map.of("endpoint", "/ws/v1/events", "subscription", "/user/queue/events", "clientSendAllowed", false,
                    "eventType", "BATTLE_STICKER", "recipients", "Opponent current authorized session only; no sender echo",
                    "schema", Map.of("$ref", "#/components/schemas/BattleStickerEnvelope"), "delivery", "Best-effort, no replay/history; HTTP receipt confirms acceptance only",
                    "cooldownMs", 4000, "receiptRetentionSeconds", 120));
        };
    }
}
