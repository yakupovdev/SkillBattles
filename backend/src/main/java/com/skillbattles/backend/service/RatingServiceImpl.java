package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.RatingDto;
import com.skillbattles.backend.dto.RatingUpdateDto;
import com.skillbattles.backend.entity.Subject;
import com.skillbattles.backend.mapper.RatingMapper;
import com.skillbattles.backend.repository.RatingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RatingServiceImpl implements RatingService {
    private final RatingRepository repository;
    private final RatingMapper mapper;

    @Override
    @Transactional
    public void initialize(UUID userId) {
        repository.saveAll(Arrays.stream(Subject.values()).map(subject -> mapper.initial(userId, subject)).toList());
        repository.flush();
    }

    @Override
    public List<RatingDto> getByUserId(UUID userId) {
        return repository.findAllByUserId(userId).stream().sorted(Comparator.comparing(rating -> rating.getSubject().ordinal()))
                .map(mapper::toDto).toList();
    }

    @Override
    @Transactional
    public void settle(List<RatingUpdateDto> updates) {
        if (updates.size() != 2 || updates.get(0).getUserId().equals(updates.get(1).getUserId())
                || updates.get(0).getSubject() != updates.get(1).getSubject()) {
            throw new IllegalArgumentException("Settlement requires two distinct users in the same subject.");
        }
        var locked = repository.lockForSettlement(updates.stream().map(RatingUpdateDto::getUserId).toList(), updates.getFirst().getSubject());
        if (locked.size() != 2) throw new IllegalStateException("Missing participant ratings.");
        for (var rating : locked) {
            var update = updates.stream().filter(item -> item.getUserId().equals(rating.getUserId())).findFirst().orElseThrow();
            if (rating.getRating() != update.getBefore() || update.getAfter() < 0) throw new IllegalStateException("Participant rating changed during the battle.");
            rating.setRating(update.getAfter());
        }
        repository.flush();
    }
}
