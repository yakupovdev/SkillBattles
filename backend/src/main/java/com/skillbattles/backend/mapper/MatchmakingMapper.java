package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import org.mapstruct.Mapper;

@Mapper(config = CommonMapperConfig.class)
public interface MatchmakingMapper {
    RematchResponse toResponse(RematchDto dto);
    RematchInvitation toResponse(RematchInvitationDto dto);
    RematchInvitationListResponse toResponse(RematchInvitationListDto dto);
    QueueEntryResponse toResponse(QueueEntryDto dto);
    DuelResponse toResponse(DuelDto dto);
    PublicPlayer toResponse(PublicPlayerDto dto);
    ActivityResponse toResponse(ActivityDto dto);
}
