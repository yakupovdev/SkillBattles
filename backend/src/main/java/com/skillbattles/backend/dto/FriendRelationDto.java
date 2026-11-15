package com.skillbattles.backend.dto;
import com.skillbattles.backend.entity.*;
import java.time.Instant;
import java.util.*;
public record FriendRelationDto(UUID id, UUID userLowId, UUID userHighId, UUID requesterId, UUID recipientId, FriendStatus status, Instant createdAt, Instant updatedAt, Instant acceptedAt, int version) {  }
