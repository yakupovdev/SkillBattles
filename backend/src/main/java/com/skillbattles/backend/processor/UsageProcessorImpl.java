package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.exception.DailyLimitException;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;
@Component @RequiredArgsConstructor
public class UsageProcessorImpl implements UsageProcessor {
    private final UsageService usage;private final SubscriptionService subscriptions;private final StreakService streaks;private final Clock clock;
    @Override @Transactional(readOnly=true) public LimitsDto limits(UUID user) {
        return limits(user,subscriptions.current(user));
    }
    @Override @Transactional(readOnly=true) public LimitsDto limits(UUID user,SubscriptionDto sub) {
        var e=sub.getEntitlements();var now=clock.instant();int used=usage.used(user,EtCalendar.date(now));
        return new LimitsDto(e.isPro()?sub.getPlanCode():"FREE",EtCalendar.ZONE.getId(),EtCalendar.date(now),5,used,e.isPro()?null:Math.max(0,5-used),EtCalendar.resetsAt(now),e.isPro()||used<5,e);
    }
    @Override public void requireAvailable(UUID user){var l=limits(user);if(!l.isCanStartRanked())throw new DailyLimitException(l.getResetsAt());}
    @Override @Transactional public boolean start(BattleDto battle,Instant at) {
        if(battle.getMode()!=BattleMode.RANKED)return true;
        var pro=subscriptions.lockProFlags(battle.getState().getPlayers().stream().map(BattlePlayerDto::getId).toList());
        boolean allowed=usage.start(battle.getId(),pro,at);
        if(allowed) pro.keySet().forEach(subscriptions::changed);return allowed;
    }
    @Override @Transactional public void finish(BattleDto battle) {
        var players=battle.getState().getPlayers();
        if(battle.getPhase()==BattlePhase.CANCELLED) {
            if(usage.refund(battle.getId()))players.stream().map(BattlePlayerDto::getId).sorted().forEach(subscriptions::changed);return;
        }
        var result=battle.getResult();boolean normal=result.getReason()==CompletionReason.NORMAL||result.getReason()==CompletionReason.OVERTIME_WIN;
        for(var p:players.stream().sorted(Comparator.comparing(BattlePlayerDto::getId)).toList())
            if((normal||p.getId().equals(result.getWinnerUserId()))&&streaks.qualify(p.getId(),result.getFinishedAt()))subscriptions.changed(p.getId());
    }
}
