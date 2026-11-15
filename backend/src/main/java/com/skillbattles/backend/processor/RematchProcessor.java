package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.RematchDto;
import com.skillbattles.backend.dto.RematchInvitationListDto;
import java.util.UUID;

public interface RematchProcessor {
    RematchDto request(UUID battle, UUID user);
    RematchDto get(UUID battle, UUID user);
    void cancel(UUID battle, UUID user);
    RematchInvitationListDto invitations(UUID user);
}
