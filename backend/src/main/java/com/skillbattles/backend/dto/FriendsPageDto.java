package com.skillbattles.backend.dto;
import com.skillbattles.backend.entity.*;
import java.time.Instant;
import java.util.*;
public record FriendsPageDto(List<FriendListItemDto> data, PaginationDto pagination) {  }
