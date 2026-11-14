package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;import com.skillbattles.backend.entity.*;import com.skillbattles.backend.service.*;import com.skillbattles.backend.exception.*;
import lombok.RequiredArgsConstructor;import org.springframework.stereotype.Component;import java.time.Clock;import java.util.*;
@Component @RequiredArgsConstructor public class RematchProcessorImpl implements RematchProcessor {
 private final MatchmakingRegistryService registry;private final BattleService battles;private final BattleAccessProcessor access;private final BattleProcessor creation;private final Clock clock;
 @Override public RematchDto request(UUID id,UUID user){
  var response=registry.transact(state->{
   RematchExpiry.expire(state,clock.instant());var b=source(id,user);var r=state.getRematches().get(id);
   if(r!=null&&!r.getStatus().equals("WAITING"))return r;
   if(r!=null&&r.getRequestedBy().contains(user))return r;
   idle(state,user);
   if(r==null){
    r=RematchDto.builder().sourceBattleId(id).status("WAITING").requestedBy(List.of(user)).expiresAt(clock.instant().plusSeconds(60)).version(1).participants(b.getState().getPlayers().stream().map(BattlePlayerDto::getId).toList()).build();
    state.getRematches().put(id,r);state.getActivities().put(user,new ActivityReservationDto(ActivityType.PRIVATE_DUEL,id,"REMATCH"));return r;
   }
   var requester=r.getRequestedBy().getFirst();
   if(!new ActivityReservationDto(ActivityType.PRIVATE_DUEL,id,"REMATCH").equals(state.getActivities().get(requester)))throw new ConflictException("ACTIVITY_CONFLICT","The other player is unavailable.");
   state.getActivities().remove(requester);
   UUID battle=creation.create(new CreateBattleDto(requester,user,b.getDisciplineCode(),BattleMode.PRIVATE));
   var matched=r.toBuilder().status("MATCHED").requestedBy(r.getParticipants()).battleId(battle).version(r.getVersion()+1).build();state.getRematches().put(id,matched);return matched;
  });
  if(response.getStatus().equals("EXPIRED"))throw new GoneException("REMATCH_EXPIRED","Rematch consent has expired.");
  if(response.getStatus().equals("CANCELLED"))throw new ConflictException("REMATCH_NOT_ALLOWED","Rematch was cancelled.");return response;
 }
 @Override public RematchDto get(UUID id,UUID user){return registry.transact(state->{access.require(battles.getForParticipant(id,user),user);RematchExpiry.expire(state,clock.instant());var r=state.getRematches().get(id);if(r==null)throw new NotFoundException("REMATCH_NOT_FOUND","No rematch consent exists.");return r;});}
 @Override public void cancel(UUID id,UUID user){registry.transact(state->{var b=battles.getForParticipant(id,user);if(b.getMode()!=BattleMode.PRIVATE||!BattleEngineImpl.terminal(b))throw new NotFoundException("BATTLE_NOT_FOUND","Battle not found.");RematchExpiry.expire(state,clock.instant());var r=state.getRematches().get(id);if(r!=null){if(r.getStatus().equals("MATCHED"))throw new ConflictException("MATCH_ALREADY_FOUND","Rematch battle already exists.");if(r.getStatus().equals("WAITING"))RematchExpiry.end(state,r,"CANCELLED");}return null;});}
 private BattleDto source(UUID id,UUID user){var b=battles.getForParticipant(id,user);access.require(b,user);if(b.getMode()!=BattleMode.PRIVATE||!BattleEngineImpl.terminal(b))throw new ConflictException("REMATCH_NOT_ALLOWED","Only a terminal private battle can be rematched.");return b;}
 private void idle(MatchmakingStateDto state,UUID user){if(state.getActivities().containsKey(user)||battles.hasActiveBattle(user))throw new ConflictException("ACTIVITY_CONFLICT","User already has an active queue, room, rematch or battle.");}
}
