package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.RatingDto;
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
}
