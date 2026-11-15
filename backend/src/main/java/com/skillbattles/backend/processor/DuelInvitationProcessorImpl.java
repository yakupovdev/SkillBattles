package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import java.time.*;
import java.util.*;

@Component @RequiredArgsConstructor
public class DuelInvitationProcessorImpl implements DuelInvitationProcessor {
    private final MatchmakingRegistryService registry;
    private final MatchmakingProcessor matchmaking;
    private final DuelInvitationReconciler reconciliation;
    private final UserService users;
    private final FriendRelationService friends;
    private final FriendPresentationProcessor presentation;
    private final RequestRateLimiter limiter;
    private final Clock clock;

    @Override public SocialCommandDto<DuelInvitationViewDto> send(UUID host,UUID duelId,UUID friend,UUID request){
        var result=registry.transact(state->{
            var now=clock.instant();reconciliation.refresh(state,now);
            var key=new InvitationReceiptKey(host,request);var receipt=state.getInvitationReceipts().get(key);
            if(receipt!=null){
                if(!receipt.duelId().equals(duelId)||!receipt.friendId().equals(friend))throw new ConflictException("IDEMPOTENCY_CONFLICT","requestId already belongs to another invitation payload.");
                return new SocialCommandDto<>(state.getDuelInvitations().get(receipt.invitationId()),false);
            }
            var room=hostRoom(state,host,duelId);
            if(room.getStatus()==DuelStatus.EXPIRED||(room.getStatus()==DuelStatus.WAITING&&!room.getExpiresAt().isAfter(now)))return new SocialCommandDto<DuelInvitationDto>(null,false);
            if(room.getStatus()!=DuelStatus.WAITING)throw new ConflictException("DUEL_NOT_JOINABLE","Room is no longer waiting.");
            if(host.equals(friend))throw friendMissing();
            lockFriends(host,friend);
            if(!new ActivityReservationDto(ActivityType.PRIVATE_DUEL,duelId).equals(state.getActivities().get(host)))throw new ConflictException("ACTIVITY_CONFLICT","The room host is unavailable.");
            var pending=state.getDuelInvitations().values().stream().filter(i->i.getDuelId().equals(duelId)&&i.getStatus()==DuelInvitationStatus.PENDING).findFirst();
            if(pending.isPresent()){
                if(!pending.get().getRecipientId().equals(friend))throw new ConflictException("DUEL_INVITATION_ALREADY_PENDING","Resolve the current room invitation first.");
                state.getInvitationReceipts().put(key,new InvitationReceiptDto(duelId,friend,pending.get().getId()));
                return new SocialCommandDto<>(pending.get(),false);
            }
            var previous=state.getDuelInvitations().values().stream().filter(i->i.getDuelId().equals(duelId)&&i.getRecipientId().equals(friend)&&i.getResolvedAt()!=null).max(Comparator.comparing(DuelInvitationDto::getResolvedAt));
            if(previous.isPresent()){var until=previous.get().getResolvedAt().plusSeconds(60);if(now.isBefore(until)){var wait=Duration.between(now,until);throw new RateLimitedException(wait.getSeconds()+(wait.getNano()>0?1:0));}}
            limiter.check("duel-invitation:"+host,30);
            Instant expiry=now.plusSeconds(60).isBefore(room.getExpiresAt())?now.plusSeconds(60):room.getExpiresAt();
            var i=DuelInvitationDto.builder().id(UUID.randomUUID()).duelId(duelId).hostId(host).recipientId(friend).disciplineCode(room.getDisciplineCode()).format(room.getFormat()).status(DuelInvitationStatus.PENDING).createdAt(now).expiresAt(expiry).version(1).build();
            state.getDuelInvitations().put(i.getId(),i);state.getInvitationReceipts().put(key,new InvitationReceiptDto(duelId,friend,i.getId()));return new SocialCommandDto<>(i,true);
        });
        if(result.value()==null)throw new GoneException("DUEL_EXPIRED","Room has expired.");
        return new SocialCommandDto<>(present(result.value()),result.created());
    }
    @Override public DuelInvitationsSnapshotDto incoming(UUID user){
        var snapshot=registry.transact(state->{var now=clock.instant();reconciliation.refresh(state,now);return new Snapshot(pending(state).stream().filter(i->i.getRecipientId().equals(user)).toList(),now);});return presentSnapshot(snapshot);
    }
    @Override public DuelInvitationsSnapshotDto outgoing(UUID host,UUID duel){
        var snapshot=registry.transact(state->{hostRoom(state,host,duel);var now=clock.instant();reconciliation.refresh(state,now);return new Snapshot(pending(state).stream().filter(i->i.getDuelId().equals(duel)).toList(),now);});return presentSnapshot(snapshot);
    }
    @Override public DuelInvitationViewDto get(UUID user,UUID id){return present(registry.transact(state->{owned(state,user,id);reconciliation.refresh(state,clock.instant());return owned(state,user,id);}));}
    @Override public DuelInvitationViewDto accept(UUID user,UUID id){
        var result=registry.transact(state->{var i=owned(state,user,id);if(!i.getRecipientId().equals(user))throw new SocialForbiddenException();reconciliation.refresh(state,clock.instant());i=owned(state,user,id);
            if(i.getStatus()!=DuelInvitationStatus.PENDING)return i;
            lockFriends(i.getHostId(),i.getRecipientId());
            matchmaking.joinInRegistry(state,user,i.getDuelId());return state.getDuelInvitations().get(id);
        });
        if(result.getStatus()==DuelInvitationStatus.EXPIRED)throw new GoneException("DUEL_INVITATION_EXPIRED","Invitation has expired.");
        if(result.getStatus()!=DuelInvitationStatus.ACCEPTED)throw new ConflictException("DUEL_INVITATION_NOT_PENDING","Invitation is no longer pending.");return present(result);
    }
    @Override public DuelInvitationViewDto decline(UUID user,UUID id){return present(registry.transact(state->{var i=owned(state,user,id);if(!i.getRecipientId().equals(user))throw new SocialForbiddenException();reconciliation.refresh(state,clock.instant());i=owned(state,user,id);if(i.getStatus()==DuelInvitationStatus.ACCEPTED)throw matched();return reconciliation.end(state,i,DuelInvitationStatus.DECLINED,null,clock.instant());}));}
    @Override public void withdraw(UUID user,UUID id){registry.transact(state->{var i=owned(state,user,id);if(!i.getHostId().equals(user))throw new SocialForbiddenException();reconciliation.refresh(state,clock.instant());i=owned(state,user,id);if(i.getStatus()==DuelInvitationStatus.ACCEPTED)throw matched();reconciliation.end(state,i,DuelInvitationStatus.CANCELLED,DuelInvitationReason.SENDER_CANCELLED,clock.instant());return null;});}
    @Override public DuelInvitationViewDto present(DuelInvitationDto i){return present(i,presentation.players(List.of(i.getHostId(),i.getRecipientId())));}
    private DuelInvitationsSnapshotDto presentSnapshot(Snapshot snapshot){var ids=new HashSet<UUID>();snapshot.values().forEach(i->{ids.add(i.getHostId());ids.add(i.getRecipientId());});var players=presentation.players(ids);return new DuelInvitationsSnapshotDto(snapshot.values().stream().filter(i->players.containsKey(i.getHostId())&&players.containsKey(i.getRecipientId())).map(i->present(i,players)).toList(),snapshot.at());}
    private DuelInvitationViewDto present(DuelInvitationDto i,Map<UUID,PublicPlayerDto> players){
        if(!players.containsKey(i.getHostId())||!players.containsKey(i.getRecipientId()))throw new NotFoundException("DUEL_INVITATION_NOT_FOUND","Invitation participant is unavailable.");
        return new DuelInvitationViewDto(i.getId(),i.getDuelId(),players.get(i.getHostId()),players.get(i.getRecipientId()),i.getDisciplineCode(),i.getFormat(),i.getStatus(),i.getReason(),i.getCreatedAt(),i.getExpiresAt(),i.getBattleId(),i.getVersion());}
    private List<DuelInvitationDto> pending(MatchmakingStateDto state){return state.getDuelInvitations().values().stream().filter(i->i.getStatus()==DuelInvitationStatus.PENDING).sorted(Comparator.comparing(DuelInvitationDto::getExpiresAt).thenComparing(i->i.getId().toString())).toList();}
    private DuelInvitationDto owned(MatchmakingStateDto state,UUID user,UUID id){var i=state.getDuelInvitations().get(id);if(i==null||!i.getHostId().equals(user)&&!i.getRecipientId().equals(user))throw new NotFoundException("DUEL_INVITATION_NOT_FOUND","Invitation not found.");return i;}
    private DuelDto hostRoom(MatchmakingStateDto state,UUID host,UUID id){var room=state.getDuels().get(id);if(room==null||!room.getHost().getId().equals(host))throw new NotFoundException("DUEL_NOT_FOUND","Room not found.");return room;}
    private void lockFriends(UUID a,UUID b){
        if(users.findByIds(List.of(a,b)).size()!=2)throw friendMissing();var pair=FriendPair.of(a,b);users.lockActiveById(pair.low());users.lockActiveById(pair.high());
        var relation=friends.pair(pair).stream().filter(r->r.status()==FriendStatus.ACCEPTED).findFirst().orElseThrow(this::friendMissing);if(friends.lock(relation.id()).status()!=FriendStatus.ACCEPTED)throw friendMissing();
    }
    private NotFoundException friendMissing(){return new NotFoundException("FRIEND_NOT_FOUND","Accepted friend not found.");}
    private ConflictException matched(){return new ConflictException("MATCH_ALREADY_FOUND","Invitation already created a battle.");}
    private record Snapshot(List<DuelInvitationDto> values,Instant at){}
}
