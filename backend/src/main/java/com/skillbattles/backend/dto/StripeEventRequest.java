package com.skillbattles.backend.dto;
import lombok.*;import java.util.Map;import io.swagger.v3.oas.annotations.media.Schema;
/** Documentation of the signed provider envelope. Runtime verification always uses raw bytes. */
@Getter @Setter public class StripeEventRequest {
 private String id;@Schema(allowableValues={"event"}) private String object;private String type;private boolean livemode;private long created;private StripeEventData data;
}
