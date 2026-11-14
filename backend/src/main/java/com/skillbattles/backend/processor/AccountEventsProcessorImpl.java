package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.mapper.BillingMapper;
import com.skillbattles.backend.service.RealtimeSessionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.context.annotation.Profile;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.*;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.transaction.*;
import org.springframework.transaction.support.TransactionTemplate;
@Component @Profile("!question-import") @Slf4j
public class AccountEventsProcessorImpl implements AccountEventsProcessor {
    private final AccountProcessor accounts;private final BillingMapper mapper;private final RealtimeSessionService sessions;private final SimpMessagingTemplate messaging;
    private final ThreadPoolTaskExecutor executor;private final TransactionTemplate reads;
    public AccountEventsProcessorImpl(AccountProcessor accounts,BillingMapper mapper,RealtimeSessionService sessions,SimpMessagingTemplate messaging,ThreadPoolTaskExecutor realtimeEventExecutor,PlatformTransactionManager tx){
        this.accounts=accounts;this.mapper=mapper;this.sessions=sessions;this.messaging=messaging;this.executor=realtimeEventExecutor;reads=new TransactionTemplate(tx);reads.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);reads.setReadOnly(true);
    }
    @Override @EventListener public void changed(AccountChangedEvent event) {
        if(!sessions.hasSubscribers())return;
        try {executor.execute(() -> {try {
            var target=sessions.target(event.userId());if(target.isEmpty())return;
            var state=reads.execute(status -> mapper.toResponse(accounts.state(event.userId())));if(state==null||!sessions.isCurrent(target.get().sessionId()))return;
            var headers=SimpMessageHeaderAccessor.create(SimpMessageType.MESSAGE);headers.setSessionId(target.get().sessionId());headers.setLeaveMutable(true);
            messaging.convertAndSendToUser(event.userId().toString(),"/queue/events",new RealtimeEvent<>(java.util.UUID.randomUUID(),"ACCOUNT_CHANGED",event.userId(),state.getSubscription().getEntitlements().getVersion(),event.occurredAt(),state),headers.getMessageHeaders());
        }catch(RuntimeException ex){log.error("Account notification failed: {}",ex.getClass().getSimpleName());}});}catch(org.springframework.core.task.TaskRejectedException ex){log.warn("Account notifications require REST recovery.");}
    }
}
