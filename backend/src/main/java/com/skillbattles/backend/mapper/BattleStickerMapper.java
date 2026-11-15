package com.skillbattles.backend.mapper;
import com.skillbattles.backend.config.CommonMapperConfig;
import com.skillbattles.backend.dto.*;
import org.mapstruct.Mapper;
@Mapper(config = CommonMapperConfig.class)
public interface BattleStickerMapper {
    BattleStickerCommandDto toDto(SendBattleStickerRequest request);
    StickerSendResponse toResponse(BattleStickerReceiptDto receipt);
}
