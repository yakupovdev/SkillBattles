package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.*;
import java.time.*;
import java.util.*;

@Component @RequiredArgsConstructor
public class FriendProcessorImpl implements FriendProcessor {
    private final UserService users;
    private final FriendRelationService relations;
    private final MatchmakingRegistryService registry;
    private final DuelInvitationReconciler invitations;
    private final FriendPresentationProcessor presentation;
    private final BasicFriendStatisticsProcessor statistics;
    private final RequestRateLimiter limiter;
    private final Clock clock;
    private final ApplicationEventPublisher events;

    @Override public FriendCodeDto code(UUID user){return new FriendCodeDto(users.friendCode(user));}
    @Override public SocialCommandDto<RelationshipDto> send(UUID user,String input){
        limiter.check("friend-request:"+user,20);String code=FriendCodeGenerator.normalize(input);
        UUID target=users.findByFriendCode(code).orElseThrow(()->new NotFoundException("FRIEND_CODE_NOT_FOUND","Friend code not found.")).getId();
        if(user.equals(target))throw new ConflictException("SELF_FRIEND_REQUEST_NOT_ALLOWED","Cannot send yourself a friend request.");
        return registry.transact(state->{
            lockPair(user,target,"FRIEND_CODE_NOT_FOUND");var records=relations.pair(FriendPair.of(user,target));
            var live=records.stream().filter(r->r.status()==FriendStatus.PENDING||r.status()==FriendStatus.ACCEPTED).findFirst();
            if(live.isPresent()){
                var r=relations.lock(live.get().id());
                if(r.status()==FriendStatus.ACCEPTED)throw new ConflictException("FRIEND_ALREADY_EXISTS","You are already friends.");
                if(!r.requesterId().equals(user))throw new ConflictException("FRIEND_REQUEST_ALREADY_RECEIVED","Accept the incoming friend request explicitly.");
                return new SocialCommandDto<>(present(r),false);
            }
            if(!records.isEmpty())cooldown(records.getFirst().updatedAt());
            var r=relations.create(user,target);changed(r);return new SocialCommandDto<>(present(r),true);
        });
    }
    @Override public RelationshipDto get(UUID user,UUID id){var r=owned(user,id);active(r);return present(r);}
    @Override public RelationshipDto respond(UUID user,UUID id,FriendStatus target){
        if(target!=FriendStatus.ACCEPTED&&target!=FriendStatus.DECLINED)throw new IllegalArgumentException("Unsupported request action.");
        return registry.transact(state->{var r=owned(user,id);if(!r.recipientId().equals(user))throw new SocialForbiddenException();lockPair(r.requesterId(),r.recipientId(),"FRIEND_REQUEST_NOT_FOUND");r=relations.lock(id);
            if(r.status()==target)return present(r);
            if(r.status()!=FriendStatus.PENDING)throw notPending();
            r=relations.change(id,target);changed(r);return present(r);
        });
    }
    @Override public void cancel(UUID user,UUID id){registry.transact(state->{var r=owned(user,id);if(!r.requesterId().equals(user))throw new SocialForbiddenException();lockPair(r.requesterId(),r.recipientId(),"FRIEND_REQUEST_NOT_FOUND");r=relations.lock(id);
        if(r.status()==FriendStatus.ACCEPTED)throw notPending();if(r.status()==FriendStatus.PENDING)changed(relations.change(id,FriendStatus.CANCELLED));return null;});}
    @Override @Transactional(readOnly=true) public FriendsPageDto friends(UUID user,int page,int size){
        page(page,size);var rows=relations.friends(user,page,size);var people=people(rows.getData());
        return new FriendsPageDto(rows.getData().stream().filter(r->visible(r,people)).map(r->new FriendListItemDto(r.id(),people.get(r.requesterId().equals(user)?r.recipientId():r.requesterId()),r.acceptedAt(),r.version())).toList(),rows.getPagination());
    }
    @Override @Transactional(readOnly=true) public FriendRequestsPageDto requests(UUID user,FriendRequestDirection direction,int page,int size){
        page(page,size);var rows=relations.requests(user,direction==FriendRequestDirection.INCOMING,page,size);var people=people(rows.getData());
        return new FriendRequestsPageDto(rows.getData().stream().filter(r->visible(r,people)).map(r->present(r,people)).toList(),rows.getPagination());
    }
    @Override public void remove(UUID user,UUID friend){registry.transact(state->{
        if(user.equals(friend))return null;
        if(users.findByIds(List.of(user,friend)).size()!=2){invitations.refresh(state,clock.instant());return null;}
        lockPair(user,friend,"FRIEND_NOT_FOUND");
        var accepted=relations.pair(FriendPair.of(user,friend)).stream().filter(r->r.status()==FriendStatus.ACCEPTED).findFirst();
        if(accepted.isPresent()){var r=relations.lock(accepted.get().id());changed(relations.change(r.id(),FriendStatus.REMOVED));}
        invitations.refresh(state,clock.instant());return null;
    });}
    @Override @Transactional public FriendProfileDto profile(UUID user,UUID friend){
        if(user.equals(friend))throw missing("FRIEND_NOT_FOUND");
        // Canonical users first, then relation; rating preparation may reacquire these user locks.
        lockPair(user,friend,"FRIEND_NOT_FOUND");
        var r=relations.pair(FriendPair.of(user,friend)).stream().filter(row->row.status()==FriendStatus.ACCEPTED).findFirst().orElseThrow(()->missing("FRIEND_NOT_FOUND"));
        r=relations.lock(r.id());if(r.status()!=FriendStatus.ACCEPTED)throw missing("FRIEND_NOT_FOUND");
        return new FriendProfileDto(presentation.players(List.of(friend)).get(friend),r.acceptedAt(),statistics.statistics(friend));
    }
    private FriendRelationDto owned(UUID user,UUID id){var r=relations.get(id);if(!r.requesterId().equals(user)&&!r.recipientId().equals(user))throw missing("FRIEND_REQUEST_NOT_FOUND");return r;}
    private void active(FriendRelationDto r){if(users.findByIds(List.of(r.requesterId(),r.recipientId())).size()!=2)throw missing("FRIEND_REQUEST_NOT_FOUND");}
    private void lockPair(UUID a,UUID b,String code){
        if(users.findByIds(List.of(a,b)).size()!=2)throw missing(code);
        var pair=FriendPair.of(a,b);users.lockActiveById(pair.low());users.lockActiveById(pair.high());
    }
    private Map<UUID,PublicPlayerDto> people(List<FriendRelationDto> rows){var ids=new HashSet<UUID>();rows.forEach(r->{ids.add(r.requesterId());ids.add(r.recipientId());});return presentation.players(ids);}
    private RelationshipDto present(FriendRelationDto r){return present(r,presentation.players(List.of(r.requesterId(),r.recipientId())));}
    private boolean visible(FriendRelationDto r,Map<UUID,PublicPlayerDto> people){return people.containsKey(r.requesterId())&&people.containsKey(r.recipientId());}
    private RelationshipDto present(FriendRelationDto r,Map<UUID,PublicPlayerDto> people){if(!visible(r,people))throw missing("FRIEND_REQUEST_NOT_FOUND");return new RelationshipDto(r.id(),people.get(r.requesterId()),people.get(r.recipientId()),r.status(),r.createdAt(),r.updatedAt(),r.acceptedAt(),r.version());}
    private void changed(FriendRelationDto r){var event=new FriendshipChangedEvent(present(r),clock.instant());TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization(){@Override public void afterCommit(){events.publishEvent(event);}});}
    private void cooldown(Instant last){var now=clock.instant();var until=last.plusSeconds(60);if(now.isBefore(until)){var wait=Duration.between(now,until);throw new RateLimitedException(wait.getSeconds()+(wait.getNano()>0?1:0));}}
    private void page(int page,int size){if(page<0||size<1||size>100)throw new BusinessValidationException("VALIDATION_ERROR","Invalid page or size.");}
    private NotFoundException missing(String code){return new NotFoundException(code,"Friend resource not found.");}
    private ConflictException notPending(){return new ConflictException("FRIEND_REQUEST_NOT_PENDING","Friend request is no longer pending.");}
}
