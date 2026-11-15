package com.skillbattles.backend.dto;

import lombok.Getter;
import java.util.*;

/** Transaction-local copy; never returned from the registry to a request or event listener. */
@Getter
public class MatchmakingStateDto {
    private final Map<UUID,DuelInvitationDto> duelInvitations = new LinkedHashMap<>();
    private final Map<InvitationReceiptKey,InvitationReceiptDto> invitationReceipts = new HashMap<>();
    private final Map<UUID,RematchDto> rematches;
    private final Map<UUID, QueueEntryDto> entries;
    private final Map<UUID, DuelDto> duels;
    private final Map<UUID, ActivityReservationDto> activities;
    public MatchmakingStateDto() { this.rematches=new LinkedHashMap<>(); this.entries = new LinkedHashMap<>(); this.duels = new LinkedHashMap<>(); this.activities = new HashMap<>(); }
    public MatchmakingStateDto(MatchmakingStateDto source) {
        this.duelInvitations.putAll(source.duelInvitations);
        this.invitationReceipts.putAll(source.invitationReceipts);
        this.rematches=new LinkedHashMap<>(source.rematches);
        this.entries = new LinkedHashMap<>(source.entries);
        this.duels = new LinkedHashMap<>(source.duels);
        this.activities = new HashMap<>(source.activities);
    }
}
