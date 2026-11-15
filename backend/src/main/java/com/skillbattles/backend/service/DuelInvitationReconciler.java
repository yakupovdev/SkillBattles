package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import java.time.Instant;
public interface DuelInvitationReconciler {
    void refresh(MatchmakingStateDto state,Instant now);
    DuelInvitationDto end(MatchmakingStateDto state,DuelInvitationDto invitation,DuelInvitationStatus status,DuelInvitationReason reason,Instant at);
}
