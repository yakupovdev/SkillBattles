package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
@Component @RequiredArgsConstructor
public class SeasonProcessorImpl implements SeasonProcessor {
    private final UserService users;
    private final RatingProcessor ratings;
    private final SeasonService seasons;
    @Override @Transactional public PageResponse<SeasonArchiveDto> history(UUID userId,String code,int page,int size) {
        users.getById(userId); ratings.prepare(userId);
        return seasons.history(userId,code,page,size);
    }
}
