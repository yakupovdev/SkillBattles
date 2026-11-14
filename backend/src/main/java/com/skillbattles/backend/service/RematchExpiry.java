package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;import com.skillbattles.backend.entity.ActivityType;import java.time.Instant;import java.util.List;
public final class RematchExpiry {
 private RematchExpiry(){}
 public static void expire(MatchmakingStateDto state,Instant now){for(var r:List.copyOf(state.getRematches().values()))if(r.getStatus().equals("WAITING")&&!r.getExpiresAt().isAfter(now))end(state,r,"EXPIRED");}
 public static RematchDto end(MatchmakingStateDto state,RematchDto r,String status){
  var ended=r.toBuilder().status(status).version(r.getVersion()+1).build();state.getRematches().put(r.getSourceBattleId(),ended);
  for(var user:r.getRequestedBy())state.getActivities().remove(user,new ActivityReservationDto(ActivityType.PRIVATE_DUEL,r.getSourceBattleId(),"REMATCH"));return ended;
 }
}
