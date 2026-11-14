package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.User;
import org.mapstruct.*;
import java.time.*;

@Mapper(config = CommonMapperConfig.class)
public interface UserMapper {
    @Mapping(target = "email", source = "emailNormalized")
    @org.mapstruct.Mapping(target="pro",ignore=true)
    UserDto toDto(User user);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "deleted", ignore = true)
    @Mapping(target = "emailNormalized", ignore = true)
    @Mapping(target = "nicknameNormalized", ignore = true)
    @Mapping(target = "passwordHash", ignore = true)
    User toEntity(RegisterDto dto);

    UserResponse toResponse(UserDto dto);
    PublicPlayer toPublicResponse(PublicPlayerDto dto);
    ProfileUpdateDto toDto(UpdateProfileRequest request);

    default Instant toUtc(LocalDateTime value) {
        return value == null ? null : value.toInstant(ZoneOffset.UTC);
    }
}
