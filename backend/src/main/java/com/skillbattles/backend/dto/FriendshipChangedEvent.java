package com.skillbattles.backend.dto;
import com.skillbattles.backend.entity.*;
import java.time.Instant;
import java.util.*;
public record FriendshipChangedEvent(RelationshipDto relationship, Instant occurredAt) {  }
