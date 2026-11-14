package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import java.util.UUID;
public interface SeasonProcessor {
    PageResponse<SeasonArchiveDto> history(UUID userId,String code,int page,int size);
}
