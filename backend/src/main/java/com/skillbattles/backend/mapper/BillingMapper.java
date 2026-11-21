package com.skillbattles.backend.mapper;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.config.CommonMapperConfig;
import org.mapstruct.*;
@Mapper(config=CommonMapperConfig.class,uses=UserMapper.class)
public interface BillingMapper {
    SubscriptionResponse toResponse(SubscriptionDto dto);
    LimitsResponse toResponse(LimitsDto dto);
    AccountState toResponse(AccountStateDto dto);
}
