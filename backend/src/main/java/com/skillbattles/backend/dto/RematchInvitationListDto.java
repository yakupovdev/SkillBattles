package com.skillbattles.backend.dto;

import lombok.Value;
import java.time.Instant;
import java.util.List;

@Value
public class RematchInvitationListDto {
    List<RematchInvitationDto> data;
    Instant serverTime;
}
