package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import java.util.*;
@Component @RequiredArgsConstructor
public class FriendPresentationProcessorImpl implements FriendPresentationProcessor {
    private final UserService users;
    private final SubscriptionService subscriptions;
    @Override public Map<UUID,PublicPlayerDto> players(Collection<UUID> ids){
        if(ids.isEmpty())return Map.of();var unique=new HashSet<>(ids);var people=users.findByIds(unique);var flags=subscriptions.proFlags(unique);var result=new HashMap<UUID,PublicPlayerDto>();
        people.forEach(u->result.put(u.getId(),PublicPlayerDto.builder().id(u.getId()).nickname(u.getNickname()).pro(flags.getOrDefault(u.getId(),false)).build()));
        return Map.copyOf(result);
    }
}
