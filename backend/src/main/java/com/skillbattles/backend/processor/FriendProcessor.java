package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import java.util.*;
public interface FriendProcessor {
    FriendCodeDto code(UUID user);
    SocialCommandDto<RelationshipDto> send(UUID user,String code);
    RelationshipDto get(UUID user,UUID id);
    RelationshipDto respond(UUID user,UUID id,FriendStatus status);
    void cancel(UUID user,UUID id);
    FriendsPageDto friends(UUID user,int page,int size);
    FriendRequestsPageDto requests(UUID user,FriendRequestDirection direction,int page,int size);
    void remove(UUID user,UUID friend);
    FriendProfileDto profile(UUID user,UUID friend);
}
