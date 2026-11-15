package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import java.util.*;
public interface FriendRelationService {
    FriendRelationDto get(UUID id);
    FriendRelationDto lock(UUID id);
    List<FriendRelationDto> pair(FriendPair pair);
    FriendRelationDto create(UUID requester,UUID recipient);
    FriendRelationDto change(UUID id,FriendStatus status);
    PageResponse<FriendRelationDto> friends(UUID user,int page,int size);
    PageResponse<FriendRelationDto> requests(UUID user,boolean incoming,int page,int size);
    Set<FriendPair> acceptedPairs(Collection<UUID> ids);
}
