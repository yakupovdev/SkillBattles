package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import java.util.*;
public interface DuelInvitationProcessor {
    SocialCommandDto<DuelInvitationViewDto> send(UUID host,UUID duel,UUID friend,UUID request);
    DuelInvitationsSnapshotDto incoming(UUID user);
    DuelInvitationsSnapshotDto outgoing(UUID host,UUID duel);
    DuelInvitationViewDto get(UUID user,UUID id);
    DuelInvitationViewDto accept(UUID user,UUID id);
    DuelInvitationViewDto decline(UUID user,UUID id);
    void withdraw(UUID user,UUID id);
    DuelInvitationViewDto present(DuelInvitationDto invitation);
}
