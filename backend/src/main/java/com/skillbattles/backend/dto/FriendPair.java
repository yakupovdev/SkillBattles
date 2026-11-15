package com.skillbattles.backend.dto;
import com.skillbattles.backend.entity.*;
import java.time.Instant;
import java.util.*;
public record FriendPair(UUID low, UUID high) {
    public static FriendPair of(UUID a, UUID b) { return a.toString().compareTo(b.toString()) < 0 ? new FriendPair(a,b) : new FriendPair(b,a); }
 }
