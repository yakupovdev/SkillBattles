package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.NotFoundException;
import com.skillbattles.backend.mapper.FriendMapper;
import com.skillbattles.backend.repository.FriendRelationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.*;
import java.time.Clock;
import java.util.*;

@Service @RequiredArgsConstructor @Transactional(readOnly=true)
public class FriendRelationServiceImpl implements FriendRelationService {
    private final FriendRelationRepository repository;
    private final FriendMapper mapper;
    private final Clock clock;
    @Override public FriendRelationDto get(UUID id){return mapper.toDto(repository.findById(id).orElseThrow(this::missing));}
    @Override @Transactional public FriendRelationDto lock(UUID id){return mapper.toDto(repository.lock(id).orElseThrow(this::missing));}
    @Override public List<FriendRelationDto> pair(FriendPair pair){return repository.findByUserLowIdAndUserHighIdOrderByCreatedAtDescIdAsc(pair.low(),pair.high()).stream().map(mapper::toDto).toList();}
    @Override @Transactional public FriendRelationDto create(UUID requester,UUID recipient){
        var pair=FriendPair.of(requester,recipient);var row=new FriendRelation();row.setUserLowId(pair.low());row.setUserHighId(pair.high());row.setRequesterId(requester);row.setRecipientId(recipient);row.setStatus(FriendStatus.PENDING);row.setVersion(1);
        return mapper.toDto(repository.saveAndFlush(row));
    }
    @Override @Transactional public FriendRelationDto change(UUID id,FriendStatus status){
        var row=repository.lock(id).orElseThrow(this::missing);
        if(row.getStatus()!=status){row.setStatus(status);row.setVersion(row.getVersion()+1);if(status==FriendStatus.ACCEPTED)row.setAcceptedAt(clock.instant());repository.flush();}
        return mapper.toDto(row);
    }
    @Override public PageResponse<FriendRelationDto> friends(UUID user,int page,int size){return page(repository.friends(user,FriendStatus.ACCEPTED,PageRequest.of(page,size,Sort.by(Sort.Order.desc("acceptedAt"),Sort.Order.asc("id")))));}
    @Override public PageResponse<FriendRelationDto> requests(UUID user,boolean incoming,int page,int size){return page(repository.requests(user,incoming,FriendStatus.PENDING,PageRequest.of(page,size,Sort.by(Sort.Order.desc("createdAt"),Sort.Order.asc("id")))));}
    @Override public Set<FriendPair> acceptedPairs(Collection<UUID> ids){
        if(ids.isEmpty())return Set.of();var result=new HashSet<FriendPair>();repository.accepted(ids,FriendStatus.ACCEPTED).forEach(r->result.add(new FriendPair(r.getUserLowId(),r.getUserHighId())));return result;
    }
    private PageResponse<FriendRelationDto> page(Page<FriendRelation> page){return new PageResponse<>(page.stream().map(mapper::toDto).toList(),new PaginationDto(page.getNumber(),page.getSize(),page.getTotalElements(),page.getTotalPages()));}
    private NotFoundException missing(){return new NotFoundException("FRIEND_REQUEST_NOT_FOUND","Friend request not found.");}
}
