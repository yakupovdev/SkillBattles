package com.skillbattles.backend.dto;
import com.skillbattles.backend.entity.ActivityType;import java.util.UUID;
public record ActivityReservationDto(ActivityType type,UUID resourceId,String resourceKind){
 public ActivityReservationDto(ActivityType type,UUID resourceId){this(type,resourceId,type==ActivityType.PRIVATE_DUEL?"DUEL":null);}
}
