package com.skillbattles.backend.mapper;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.SubscriptionAccount;
import com.skillbattles.backend.config.CommonMapperConfig;
import org.mapstruct.*;
@Mapper(config=CommonMapperConfig.class,uses=UserMapper.class)
public interface BillingMapper {
    BillingAccountDto account(SubscriptionAccount entity);
    SubscriptionResponse toResponse(SubscriptionDto dto);
    SubscriptionPlan toResponse(SubscriptionPlanDto dto);
    CheckoutResponse toResponse(CheckoutDto dto);
    PortalResponse toResponse(PortalDto dto);
    LimitsResponse toResponse(LimitsDto dto);
    AccountState toResponse(AccountStateDto dto);
}
