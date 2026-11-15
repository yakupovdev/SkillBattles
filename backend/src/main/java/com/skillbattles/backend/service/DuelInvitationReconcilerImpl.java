package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.Instant;
import java.util.*;

@Service @RequiredArgsConstructor
public class DuelInvitationReconcilerImpl implements DuelInvitationReconciler {
    private final FriendRelationService friends;
    @Override public void refresh(MatchmakingStateDto state,Instant now){
        var pending=state.getDuelInvitations().values().stream().filter(i->i.getStatus()==DuelInvitationStatus.PENDING).toList();
        if(pending.isEmpty())return;
        var ids=new HashSet<UUID>();pending.forEach(i->{ids.add(i.getHostId());ids.add(i.getRecipientId());});
        var accepted=friends.acceptedPairs(ids); // One batch, including active-user filtering, not one lookup per invitation.
        for(var i:pending){
            var room=state.getDuels().get(i.getDuelId());
            if(room==null||room.getStatus()==DuelStatus.CANCELLED){end(state,i,DuelInvitationStatus.CANCELLED,DuelInvitationReason.DUEL_CANCELLED,now);}
            else if(room.getStatus()==DuelStatus.EXPIRED || (room.getStatus()==DuelStatus.WAITING && !room.getExpiresAt().isAfter(now))){end(state,i,DuelInvitationStatus.EXPIRED,DuelInvitationReason.DUEL_EXPIRED,room.getExpiresAt());}
            else if(room.getStatus()==DuelStatus.MATCHED){
                if(room.getGuest()!=null && room.getGuest().getId().equals(i.getRecipientId()))state.getDuelInvitations().put(i.getId(),i.toBuilder().status(DuelInvitationStatus.ACCEPTED).battleId(room.getBattleId()).version(i.getVersion()+1).resolvedAt(now).build());
                else end(state,i,DuelInvitationStatus.CANCELLED,DuelInvitationReason.DUEL_FILLED,now);
            } else if(!accepted.contains(FriendPair.of(i.getHostId(),i.getRecipientId())))end(state,i,DuelInvitationStatus.CANCELLED,DuelInvitationReason.FRIEND_REMOVED,now);
            else if(!i.getExpiresAt().isAfter(now))end(state,i,DuelInvitationStatus.EXPIRED,DuelInvitationReason.INVITATION_EXPIRED,i.getExpiresAt());
        }
    }
    @Override public DuelInvitationDto end(MatchmakingStateDto state,DuelInvitationDto i,DuelInvitationStatus status,DuelInvitationReason reason,Instant at){
        if(i.getStatus()!=DuelInvitationStatus.PENDING)return i;
        var result=i.toBuilder().status(status).reason(reason).resolvedAt(at).version(i.getVersion()+1).build();state.getDuelInvitations().put(i.getId(),result);return result;
    }
}
