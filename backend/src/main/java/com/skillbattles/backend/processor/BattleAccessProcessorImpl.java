package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.service.*;
import com.skillbattles.backend.exception.*;
import com.skillbattles.backend.mapper.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.util.*;
@Component @RequiredArgsConstructor @Transactional(readOnly=true)
public class BattleAccessProcessorImpl implements BattleAccessProcessor {
    private final BattleService battles;private final SubscriptionService subscriptions;
    private final BattleSnapshotMapper mapper;private final BattleReviewMapper reviews;private final BattleHistoryMapper histories;
    @Override public void require(BattleDto battle,UUID user) {
        require(battle,user,subscriptions.entitlements(user));
    }
    private void require(BattleDto battle,UUID user,EntitlementsDto e) {
        if(battle.getState().getPlayers().stream().noneMatch(p -> p.getId().equals(user)))throw new NotFoundException("BATTLE_NOT_FOUND","Battle not found.");
        if(BattleEngineImpl.terminal(battle)&&!e.isPro()&&!battles.recentTerminal(user,10).contains(battle.getId()))throw new HistoryAccessException();
    }
    private AnswerAccessDto access(EntitlementsDto e,boolean terminal) {return new AnswerAccessDto(e.isPro(),terminal&&e.isPro(),e.getVersion());}
    private void answers(List<AnswerViewDto> answers,UUID user,boolean pro) {if(!pro)answers.stream().filter(a -> !a.getUserId().equals(user)).forEach(a -> a.setSelectedOptionId(null));}
    private void badges(BattleResultDto result,Map<UUID,Boolean> flags) {if(result!=null)result.getPlayers().forEach(p -> p.setPro(flags.getOrDefault(p.getId(),false)));}
    @Override public BattleSnapshotDto snapshot(BattleDto battle,UUID user,Instant at) {
        var e=subscriptions.entitlements(user);require(battle,user,e);var dto=mapper.snapshot(battle,user,at);dto.setEntitlements(e);
        var flags=subscriptions.proFlags(battle.getState().getPlayers().stream().map(BattlePlayerDto::getId).toList());dto.getPlayers().forEach(p -> p.setPro(flags.getOrDefault(p.getId(),false)));
        if(dto.getRound()!=null&&dto.getRound().getReveal()!=null) {var reveal=dto.getRound().getReveal();if(!e.isPro())reveal.setCorrectOptionId(null);answers(reveal.getAnswers(),user,e.isPro());reveal.setAnswerAccess(access(e,BattleEngineImpl.terminal(battle)));}
        badges(dto.getResult(),flags);return dto;
    }
    @Override public BattleResultDto result(BattleDto battle,UUID user) {require(battle,user);var dto=mapper.result(battle,user);badges(dto,subscriptions.proFlags(battle.getState().getPlayers().stream().map(BattlePlayerDto::getId).toList()));return dto;}
    @Override public BattleReviewDto review(BattleDto battle,UUID user) {
        var e=subscriptions.entitlements(user);require(battle,user,e);var dto=reviews.review(battle);dto.setAnswerAccess(access(e,true));
        dto.getRounds().forEach(r -> {if(!e.isPro()){r.getQuestion().setCorrectOptionId(null);r.getQuestion().setExplanation(null);}answers(r.getAnswers(),user,e.isPro());});return dto;
    }
    @Override public BattleHistoryPage history(BattleHistoryQueryDto query) {
        Integer limit=subscriptions.entitlements(query.getUserId()).getHistoryMatchLimit();var page=battles.history(query,limit);
        var flags=subscriptions.proFlags(page.getData().stream().map(r -> r.getOpponent().getId()).toList());page.getData().forEach(r -> r.setOpponent(PublicPlayerDto.builder().id(r.getOpponent().getId()).nickname(r.getOpponent().getNickname()).pro(flags.getOrDefault(r.getOpponent().getId(),false)).build()));
        return new BattleHistoryPage(page.getData().stream().map(histories::toResponse).toList(),page.getPagination(),limit);
    }
}
