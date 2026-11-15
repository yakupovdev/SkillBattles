package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import java.util.*;
public interface BasicFriendStatisticsProcessor { List<FriendDisciplineStatisticsDto> statistics(UUID user); }
