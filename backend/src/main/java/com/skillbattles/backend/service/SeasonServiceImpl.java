package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.repository.SeasonRepository;
import com.skillbattles.backend.mapper.SeasonMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.PageRequest;
import java.time.Clock;
import java.util.*;
@Service @RequiredArgsConstructor @Transactional(readOnly=true)
public class SeasonServiceImpl implements SeasonService {
    private final SeasonRepository repository;
    private final SeasonMapper mapper;
    private final Clock clock;
    private final DisciplineService disciplines;
    @Override public SeasonDto current() {return SeasonCalendar.at(clock.instant());}
    @Override @Transactional public void archive(SeasonArchiveDto dto) {
        var previous=repository.findByUserIdAndDisciplineCodeAndSeasonId(dto.getUserId(),dto.getDisciplineCode(),dto.getSeasonId());
        if(previous.isPresent()) {
            if(!mapper.toDto(previous.get()).equals(dto)) throw new IllegalStateException("Season archive is immutable.");
            return;
        }
        repository.saveAndFlush(mapper.create(dto));
    }
    @Override public PageResponse<SeasonArchiveDto> history(UUID userId,String code,int page,int size) {
        if(page<0 || size<1 || size>100) throw new BusinessValidationException("VALIDATION_ERROR","Invalid season pagination.");
        if(code!=null) try {disciplines.get(code);} catch(BusinessException ex) {throw new BusinessValidationException("VALIDATION_ERROR","Invalid discipline filter.");}
        if((long)page*size>Integer.MAX_VALUE) {
            var first=repository.history(userId,code,PageRequest.of(0,size));
            return new PageResponse<>(List.of(),new PaginationDto(page,size,first.getTotalElements(),first.getTotalPages()));
        }
        return PageResponse.from(repository.history(userId,code,PageRequest.of(page,size)),mapper::toDto);
    }
}
