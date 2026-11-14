package com.skillbattles.backend.service;
import com.skillbattles.backend.repository.UsageRepository;
import com.skillbattles.backend.entity.RankedUsage;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;
@Service @RequiredArgsConstructor @Transactional(readOnly=true)
public class UsageServiceImpl implements UsageService {
    private final UsageRepository repository;
    @Override public int used(UUID user,LocalDate day) {return Math.toIntExact(repository.countByUserIdAndUsageDateAndRefundedFalse(user,day));}
    @Override @Transactional public boolean start(UUID battle,Map<UUID,Boolean> pro,Instant at) {
        var users=pro.keySet().stream().sorted().toList();if(users.size()!=2)throw new IllegalArgumentException("Two players are required.");
        users.forEach(repository::lockUser);
        var old=repository.findByBattleId(battle);if(!old.isEmpty()) {if(old.size()!=2)throw new IllegalStateException("Incomplete quota reservation.");return true;}
        var day=EtCalendar.date(at);
        if(users.stream().anyMatch(id -> !pro.get(id) && used(id,day)>=5))return false;
        for(var id:users) {var row=new RankedUsage();row.setUserId(id);row.setBattleId(battle);row.setUsageDate(day);row.setStartedAt(at);repository.save(row);}repository.flush();return true;
    }
    @Override @Transactional public boolean refund(UUID battle) {
        repository.users(battle).stream().sorted().forEach(repository::lockUser);
        return repository.refund(battle)>0;
    }
}
