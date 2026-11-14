package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.SubscriptionAccount;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.mapper.BillingMapper;
import com.skillbattles.backend.repository.SubscriptionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.*;
import org.springframework.context.ApplicationEventPublisher;
import java.time.*;
import java.util.*;
@Service @RequiredArgsConstructor @Transactional(readOnly=true)
public class SubscriptionServiceImpl implements SubscriptionService {
    private final SubscriptionRepository repository;
    private final BillingMapper mapper;
    private final Clock clock;
    private final ApplicationEventPublisher events;
    @Override @Transactional public void initialize(UUID id) {repository.initialize(id);}
    @Override public BillingAccountDto account(UUID id) {return repository.findByUserId(id).map(mapper::account).orElseGet(() -> {var dto=new BillingAccountDto();dto.setUserId(id);dto.setPlanCode("FREE");dto.setStatus("NONE");dto.setVersion(1);dto.setCheckouts(Map.of());return dto;});}
    @Override public Optional<UUID> owner(String customer) {return repository.findByCustomerId(customer).map(SubscriptionAccount::getUserId);}
    private boolean active(BillingAccountDto a) {return active(a,clock.instant());}
    private boolean active(BillingAccountDto a,Instant at) {return a.isPaid() && "ACTIVE".equals(a.getStatus()) && a.getCurrentPeriodStart()!=null && !at.isBefore(a.getCurrentPeriodStart()) && a.getCurrentPeriodEnd()!=null && at.isBefore(a.getCurrentPeriodEnd());}
    @Override public EntitlementsDto entitlements(UUID id) {return entitlements(account(id));}
    private EntitlementsDto entitlements(BillingAccountDto a) {
        boolean pro=active(a);int version=a.getVersion()+(a.isProActive()&&!pro?1:0);
        return new EntitlementsDto(pro,version,pro,pro?null:10,pro,pro,pro,pro);
    }
    @Override public SubscriptionDto current(UUID id) {
        var a=account(id);var e=entitlements(a);
        String status="ACTIVE".equals(a.getStatus())&&a.getCurrentPeriodEnd()!=null&&!clock.instant().isBefore(a.getCurrentPeriodEnd())?"EXPIRED":a.getStatus();
        return new SubscriptionDto(a.getPlanCode(),status,"TEST",a.getCurrentPeriodStart(),a.getCurrentPeriodEnd(),a.isCancelAtPeriodEnd(),e);
    }
    @Override public Map<UUID,Boolean> proFlags(Collection<UUID> ids) {
        Map<UUID,Boolean> flags=new HashMap<>();ids.forEach(id -> flags.put(id,false));
        if(!ids.isEmpty()) repository.findAllByUserIdIn(ids).forEach(a -> flags.put(a.getUserId(),active(mapper.account(a))));return flags;
    }
    @Override @Transactional public Map<UUID,Boolean> lockProFlags(Collection<UUID> ids) {
        var rows=ids.stream().sorted().map(this::lock).toList();Instant at=clock.instant();Map<UUID,Boolean> flags=new TreeMap<>();
        rows.forEach(a -> flags.put(a.getUserId(),active(mapper.account(a),at)));return flags;
    }
    private SubscriptionAccount lock(UUID id) {repository.initialize(id);return repository.lock(id).orElseThrow();}
    private void notifyChange(SubscriptionAccount a) {
        a.setVersion(Math.addExact(a.getVersion(),1));var event=new AccountChangedEvent(a.getUserId(),a.getVersion(),clock.instant());
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization(){@Override public void afterCommit(){events.publishEvent(event);}});
    }
    private void expire(SubscriptionAccount a) {
        if(a.isProActive()&&!active(mapper.account(a))) {a.setProActive(false);if("ACTIVE".equals(a.getStatus())) a.setStatus("EXPIRED");notifyChange(a);}
    }
    @Override @Transactional public CheckoutIntentDto reserve(UUID id,String plan,UUID requestId) {
        var a=lock(id);expire(a);var old=a.getCheckouts().get(requestId);
        if(old!=null) {
            if(!old.getPlanCode().equals(plan)) throw new ConflictException("CHECKOUT_IN_PROGRESS","Request ID already belongs to another checkout.");
            if(old.getCheckout()==null&&!old.getReservedUntil().isAfter(clock.instant()))throw new ConflictException("CHECKOUT_IN_PROGRESS","Uncertain checkout reservation expired; use a new request ID.");
            return old;
        }
        if(active(mapper.account(a))) throw new ConflictException("SUBSCRIPTION_ALREADY_ACTIVE","A subscription is already active.");
        if(a.getCheckouts().values().stream().anyMatch(i -> i.getReservedUntil().isAfter(clock.instant()))) throw new ConflictException("CHECKOUT_IN_PROGRESS","A checkout is already in progress.");
        var intent=new CheckoutIntentDto(plan,clock.instant().plus(Duration.ofHours(24)),null);
        var copy=new HashMap<>(a.getCheckouts());copy.put(requestId,intent);a.setCheckouts(copy);repository.flush();return intent;
    }
    @Override @Transactional public void bindCustomer(UUID id,String customer) {
        var a=lock(id);if(a.getCustomerId()!=null&&!a.getCustomerId().equals(customer)) throw new IllegalStateException("Customer binding is immutable.");a.setCustomerId(customer);repository.flush();
    }
    @Override @Transactional public void checkoutCreated(UUID id,UUID requestId,CheckoutDto dto) {
        var a=lock(id);var old=a.getCheckouts().get(requestId);if(old==null) throw new IllegalStateException("Checkout has no reservation.");
        var copy=new HashMap<>(a.getCheckouts());copy.put(requestId,new CheckoutIntentDto(old.getPlanCode(),dto.getExpiresAt(),dto));a.setCheckouts(copy);repository.flush();
    }
    @Override public boolean processed(String event) {return repository.hasEvent(event);}
    @Override @Transactional public void apply(UUID id,String event,ProviderSubscriptionDto p,String plan) {
        var a=lock(id);if(a.getEvents().contains(event)) return;expire(a);
        if(!Objects.equals(a.getCustomerId(),p.getCustomerId()) || p.isLiveMode()) throw new BusinessValidationException("INVALID_WEBHOOK_EVENT","Invalid test subscription binding.");
        var before=mapper.account(a);
        a.setSubscriptionId(p.getSubscriptionId());a.setPlanCode(plan);a.setStatus(p.getStatus());a.setCurrentPeriodStart(p.getCurrentPeriodStart());a.setCurrentPeriodEnd(p.getCurrentPeriodEnd());
        a.setCancelAtPeriodEnd(p.isCancelAtPeriodEnd());a.setPaid(p.isInvoicePaid());a.setProActive(active(mapper.account(a)));
        // Only a verified paid activation closes the in-flight checkout. A late cancellation
        // of an older subscription must never release a newer still-open session.
        if(a.isProActive()) a.setCheckouts(new HashMap<>(a.getCheckouts().entrySet().stream().collect(java.util.stream.Collectors.toMap(Map.Entry::getKey,e -> new CheckoutIntentDto(e.getValue().getPlanCode(),clock.instant(),e.getValue().getCheckout())))));
        if(!before.equals(mapper.account(a))) notifyChange(a);
        a.getEvents().add(event);repository.flush();
    }
    @Override @Transactional public void changed(UUID id) {var a=lock(id);expire(a);notifyChange(a);repository.flush();}
    @Override @Transactional public void expire() {for(var id:repository.expiring(clock.instant()).stream().sorted().toList()) {var a=lock(id);expire(a);}repository.flush();}
}
