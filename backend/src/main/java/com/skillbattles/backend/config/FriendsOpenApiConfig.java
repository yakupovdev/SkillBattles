package com.skillbattles.backend.config;
import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.context.annotation.*;
import java.util.*;
@Configuration
public class FriendsOpenApiConfig {
    @Bean OpenApiCustomizer friendsRealtimeContract(){return api->api.addExtension("x-friends-events",Map.of(
            "endpoint","/ws/v1/events","subscription","/user/queue/events","protocol","Native STOMP 1.2",
            "envelopeFields",List.of("eventId","type","resourceId","version","occurredAt","data"),
            "events",Map.of("FRIENDSHIP_CHANGED",Map.of("resourceId","relationship UUID","dataSchema","#/components/schemas/RelationshipResponse","durability","Persistent state; REST recovery; best-effort events"),
                    "DUEL_INVITATION_CHANGED",Map.of("resourceId","invitation UUID","dataSchema","#/components/schemas/DuelInvitationResponse","durability","One-process memory; accepted battles use existing persistent recovery")),
            "delivery","Both authorized participants, after commit, current personal sessions only; no event on unchanged retries"));}
}
