package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.RankTierDto;
import com.skillbattles.backend.mapper.RankMapper;
import com.skillbattles.backend.repository.RankRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service @RequiredArgsConstructor @Transactional(readOnly = true)
public class RankServiceImpl implements RankService {
    private final RankRepository repository;
    private final RankMapper mapper;
    @Override public List<RankTierDto> tiers() {
        var result = repository.findAllByOrderByFloorRatingAsc().stream().map(mapper::toDto).toList();
        int floor = 0;
        if (result.size() != 27) throw new IllegalStateException("Rank catalogue must contain 27 tiers.");
        for (int i = 0; i < result.size(); i++) {
            var tier = result.get(i);
            if (tier.getFloorRating() != floor || (i == result.size() - 1) != (tier.getCeilingExclusive() == null)) throw new IllegalStateException("Rank catalogue must cover every nonnegative rating.");
            if (tier.getCeilingExclusive() != null) floor = tier.getCeilingExclusive();
        }
        return result;
    }
}
