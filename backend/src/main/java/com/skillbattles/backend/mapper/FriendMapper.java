package com.skillbattles.backend.mapper;
import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import org.mapstruct.*;
import java.time.*;

@Mapper(config=CommonMapperConfig.class)
public interface FriendMapper {
    FriendRelationDto toDto(FriendRelation relation);
    RelationshipResponse toResponse(RelationshipDto dto);
    FriendCodeResponse toResponse(FriendCodeDto dto);
    FriendsPage toResponse(FriendsPageDto dto);
    FriendRequestsPage toResponse(FriendRequestsPageDto dto);
    FriendProfileResponse toResponse(FriendProfileDto dto);
    DuelInvitationResponse toResponse(DuelInvitationViewDto dto);
    DuelInvitationsSnapshot toResponse(DuelInvitationsSnapshotDto dto);
    default Instant utc(LocalDateTime value){return value==null?null:value.toInstant(ZoneOffset.UTC);}
}
