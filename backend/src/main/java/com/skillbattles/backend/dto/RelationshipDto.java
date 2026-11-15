package com.skillbattles.backend.dto;
import com.skillbattles.backend.entity.*;
import java.time.Instant;
import java.util.*;
public record RelationshipDto(UUID id, PublicPlayerDto requester, PublicPlayerDto recipient, FriendStatus status, Instant createdAt, Instant updatedAt, Instant acceptedAt, int version) {  }
