package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import java.util.*;
public interface FriendPresentationProcessor { Map<UUID,PublicPlayerDto> players(Collection<UUID> ids); }
