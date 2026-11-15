package com.skillbattles.backend.dto;
import com.skillbattles.backend.entity.*;
import java.time.Instant;
import java.util.*;
public record FriendListItemDto(UUID relationshipId, PublicPlayerDto friend, Instant friendsSince, int version) {  }
