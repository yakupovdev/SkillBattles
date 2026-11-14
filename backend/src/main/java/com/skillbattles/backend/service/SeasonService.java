package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;
import java.util.UUID;
public interface SeasonService {
    SeasonDto current();
    void archive(SeasonArchiveDto dto);
    PageResponse<SeasonArchiveDto> history(UUID userId,String code,int page,int size);
}
