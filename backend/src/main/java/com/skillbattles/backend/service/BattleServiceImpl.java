package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.exception.NotFoundException;
import com.skillbattles.backend.mapper.BattleMapper;
import com.skillbattles.backend.mapper.BattleHistoryMapper;
import com.skillbattles.backend.exception.BusinessValidationException;
import org.springframework.data.domain.*;
import com.skillbattles.backend.repository.BattleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import java.math.BigDecimal;
import java.time.Instant;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class BattleServiceImpl implements BattleService {
    private final BattleRepository repository;
    private final BattleMapper mapper;
    private final BattleHistoryMapper historyMapper;
    private final DisciplineService disciplines;

    @Override public List<BattleDto> finishedHistory(UUID userId) {return repository.finishedHistory(userId).stream().map(mapper::toDto).toList();}

    @Override @Transactional
    public BattleDto create(BattleDto dto) { return mapper.toDto(repository.saveAndFlush(mapper.create(dto))); }

    @Override @Transactional
    public BattleDto lock(UUID id) { return mapper.toDto(repository.lockById(id).orElseThrow(BattleServiceImpl::missing)); }

    @Override public BattleDto getForParticipant(UUID id, UUID userId) {
        return mapper.toDto(repository.findForParticipant(id, userId).orElseThrow(BattleServiceImpl::missing));
    }

    @Override public List<UUID> recentTerminal(UUID userId,int limit) {return repository.recentTerminal(userId,PageRequest.of(0,limit));}
    @Override public PageResponse<BattleHistoryItemDto> history(BattleHistoryQueryDto query) {return history(query,null);}
    @Override public PageResponse<BattleHistoryItemDto> history(BattleHistoryQueryDto query,Integer limit) {
        if (query.getDisciplineCode() != null) {
            try { disciplines.get(query.getDisciplineCode()); }
            catch (com.skillbattles.backend.exception.BusinessException ex) { throw new BusinessValidationException("VALIDATION_ERROR", "Invalid discipline filter."); }
        }
        if (query.getPage() < 0 || query.getSize() < 1 || query.getSize() > 100 || query.getSort() == null
                || !Set.of("createdAt,asc", "createdAt,desc").contains(query.getSort()))
            throw new BusinessValidationException("VALIDATION_ERROR", "Invalid history pagination or sort.");
        if(limit!=null) {
            var ids=recentTerminal(query.getUserId(),limit);
            if(ids.isEmpty()) return new PageResponse<>(List.of(),new PaginationDto(query.getPage(),query.getSize(),0,0));
            var direction=query.getSort().endsWith(",asc")?Sort.Direction.ASC:Sort.Direction.DESC;
            long offset=(long)query.getPage()*query.getSize();
            var page=repository.limitedHistory(query.getUserId(),query.getDisciplineCode(),query.getMode(),ids,PageRequest.of(offset>Integer.MAX_VALUE?0:query.getPage(),query.getSize(),Sort.by(direction,"createdAt","id")));
            if(offset>Integer.MAX_VALUE) return new PageResponse<>(List.of(),new PaginationDto(query.getPage(),query.getSize(),page.getTotalElements(),page.getTotalPages()));
            return PageResponse.from(page,row -> historyMapper.history(row,query.getUserId()));
        }
        if ((long) query.getPage() * query.getSize() > Integer.MAX_VALUE) {
            // JPA offsets are int32. A valid but distant page is empty, not a server error.
            long total = repository.countHistory(query.getUserId(), query.getDisciplineCode(), query.getMode());
            int pages = Math.toIntExact((total + query.getSize() - 1) / query.getSize());
            return new PageResponse<>(List.of(), new PaginationDto(query.getPage(), query.getSize(), total, pages));
        }
        Sort.Direction direction = query.getSort().endsWith(",asc") ? Sort.Direction.ASC : Sort.Direction.DESC;
        var page = repository.history(query.getUserId(), query.getDisciplineCode(), query.getMode(),
                PageRequest.of(query.getPage(), query.getSize(), Sort.by(direction, "createdAt", "id")));
        return PageResponse.from(page, row -> historyMapper.history(row, query.getUserId()));
    }

    @Override @Transactional
    public void save(BattleDto dto) {
        var entity = repository.lockById(dto.getId()).orElseThrow(BattleServiceImpl::missing);
        mapper.update(dto, entity);
        repository.flush();
    }

    @Override public boolean hasActiveRankedBattle(UUID userId,String code) {return repository.hasActiveRankedBattle(userId,code);}
    @Override public boolean hasActiveBattle(UUID userId) { return repository.hasActiveBattle(userId); }
    @Override public List<UUID> activeIds() { return repository.activeIds(); }
    @Override public List<UUID> activeIdsForUser(UUID userId) { return repository.activeIdsForUser(userId); }

    @Override
    public List<QuestionSeenDto> recentQuestionShows(UUID userId, String disciplineCode, int battleLimit) {
        if (battleLimit < 1) throw new IllegalArgumentException("History window must be positive.");
        return repository.recentQuestionShows(userId, disciplineCode, battleLimit).stream()
                .map(row -> new QuestionSeenDto(UUID.fromString(row.getQuestionId()), shownAt(row.getShownAt()))).toList();
    }

    private Instant shownAt(String value) {
        // Hibernate JSONB uses epoch seconds; also support snapshots written as ISO-8601.
        if (value.contains("T")) return Instant.parse(value);
        BigDecimal seconds = new BigDecimal(value);
        return Instant.ofEpochSecond(seconds.longValue(), seconds.remainder(BigDecimal.ONE).movePointRight(9).longValueExact());
    }

    @Override
    public List<BattleCountsDto> statistics(UUID userId) {
        return repository.statistics(userId).stream().map(row -> {
            MatchCountsDto counts = new MatchCountsDto();
            counts.setWins(Math.toIntExact(row.getWins()));
            counts.setLosses(Math.toIntExact(row.getLosses()));
            counts.setDraws(Math.toIntExact(row.getDraws()));
            counts.setPlayed(Math.toIntExact(row.getPlayed()));
            return new BattleCountsDto(row.getDisciplineCode(), row.getMode(), counts);
        }).toList();
    }

    private static NotFoundException missing() { return new NotFoundException("BATTLE_NOT_FOUND", "Battle not found."); }
}
