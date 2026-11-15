package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;

public interface RealtimeProcessor {
    void battleStickerAccepted(BattleStickerAcceptedEvent event);
    void friendshipChanged(FriendshipChangedEvent event);
    void duelInvitationChanged(DuelInvitationChangedEvent event);
    void rematchChanged(RematchChangedEvent event);
    void presenceChanged(PresenceChangedEvent event);
    void battleChanged(BattleChangedEvent event);
    void activityChanged(ActivityChangedEvent event);
}
