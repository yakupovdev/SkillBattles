package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.SubscriptionAccount;
import com.skillbattles.backend.repository.SubscriptionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.*;
import org.springframework.context.ApplicationEventPublisher;
import java.time.Clock;
import java.util.*;

@Service @RequiredArgsConstructor @Transactional(readOnly=true)
public class SubscriptionServiceImpl implements SubscriptionService {
    private final SubscriptionRepository repository;
    private final Clock clock;
    private final ApplicationEventPublisher events;

    @Override @Transactional public void initialize(UUID id) {repository.initialize(id);}
    @Override public EntitlementsDto entitlements(UUID id) {
        return repository.findByUserId(id).map(this::entitlements).orElseGet(() -> entitlements(false,1));
    }
    private EntitlementsDto entitlements(SubscriptionAccount account) {
        return entitlements(account.isProActive(),account.getVersion());
    }
    private EntitlementsDto entitlements(boolean pro,int version) {
        return new EntitlementsDto(pro,version,pro,pro?null:10,pro,pro,pro,pro);
    }
    @Override public SubscriptionDto current(UUID id) {
        var e=entitlements(id);
        return new SubscriptionDto(e.isPro()?"PRO":"FREE",e.isPro()?"ACTIVE":"NONE","NONE",null,null,false,e);
    }
    @Override public Map<UUID,Boolean> proFlags(Collection<UUID> ids) {
        Map<UUID,Boolean> flags=new HashMap<>();ids.forEach(id -> flags.put(id,false));
        if(!ids.isEmpty()) repository.findAllByUserIdIn(ids).forEach(a -> flags.put(a.getUserId(),a.isProActive()));
        return flags;
    }
    @Override @Transactional public Map<UUID,Boolean> lockProFlags(Collection<UUID> ids) {
        Map<UUID,Boolean> flags=new TreeMap<>();
        ids.stream().distinct().sorted().map(this::lock).forEach(a -> flags.put(a.getUserId(),a.isProActive()));
        return flags;
    }
    private SubscriptionAccount lock(UUID id) {repository.initialize(id);return repository.lock(id).orElseThrow();}
    @Override @Transactional public void changed(UUID id) {
        var a=lock(id);a.setVersion(Math.addExact(a.getVersion(),1));
        var event=new AccountChangedEvent(a.getUserId(),a.getVersion(),clock.instant());
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization(){
            @Override public void afterCommit(){events.publishEvent(event);}
        });
        repository.flush();
    }
}
