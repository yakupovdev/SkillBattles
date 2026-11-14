package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import java.util.UUID;
public interface ProfileProcessor { UserDto update(UUID userId, ProfileUpdateDto dto); }
