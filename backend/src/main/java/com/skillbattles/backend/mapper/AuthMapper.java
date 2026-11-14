package com.skillbattles.backend.mapper;

import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import org.mapstruct.*;

@Mapper(config = CommonMapperConfig.class, uses = UserMapper.class)
public interface AuthMapper {
    RegisterDto toDto(RegisterRequest request);
    LoginDto toDto(LoginRequest request);

    @Mapping(target = "accessToken", source = "tokens.accessToken")
    @Mapping(target = "refreshToken", source = "tokens.refreshToken")
    @Mapping(target = "accessExpiresIn", source = "tokens.accessExpiresIn")
    @Mapping(target = "refreshExpiresIn", source = "tokens.refreshExpiresIn")
    @Mapping(target = "tokenType", constant = "Bearer")
    AuthResponse toResponse(AuthDto dto);
}
