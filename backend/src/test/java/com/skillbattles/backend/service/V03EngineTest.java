package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.mapper.BattleSnapshotMapper;
import org.mapstruct.factory.Mappers;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import java.time.*;
import java.util.*;
import static com.skillbattles.backend.BattleFixtures.*;
import static org.assertj.core.api.Assertions.*;

class V03EngineTest {
    private final BattleEngine engine=new BattleEngineImpl();
    private final BattleSnapshotMapper mapper=Mappers.getMapper(BattleSnapshotMapper.class);
    private BattleDto started(int rounds) {
        var battle=waiting(rounds,BattleMode.RANKED,1000,1000);
        engine.ready(battle,player(battle,0),START);engine.ready(battle,player(battle,1),START);
        engine.advance(battle,START.plusSeconds(3));return battle;
    }
    private void send(BattleDto battle,int player,boolean correct,long ms) {
        Instant at=round(battle).getStartedAt().plusMillis(ms);
        engine.answer(battle,player(battle,player),answer(battle,correct),at,at);
    }
    @ParameterizedTest @CsvSource({"0,200","1,199","5000,100","9999,0"})
    void speedUsesTwoHundredFloorAndDoesNotLeakBeforeReveal(long elapsed,int bonus) {
        var battle=started(5);round(battle).setBasePoints(800);
        send(battle,0,true,elapsed);
        var accepted=round(battle).getAnswers().getFirst();
        assertThat(accepted.getBasePoints()).isEqualTo(800);assertThat(accepted.getSpeedBonus()).isEqualTo(bonus);
        assertThat(accepted.getPoints()).isEqualTo(800+bonus);
        var snapshot=mapper.snapshot(battle,player(battle,1),round(battle).getStartedAt().plusMillis(elapsed));
        assertThat(snapshot.getRound().getReveal()).isNull();assertThat(snapshot.getRound().getMySelectedOptionId()).isNull();
        assertThat(snapshot.getPlayers()).allSatisfy(p -> {assertThat(p.getScore()).isZero();assertThat(p.getStreak()).isZero();});
    }
    @Test void exactDeadlineRejectsAndTimeoutResetsStreak() {
        var battle=started(2);battle.getState().getPlayers().getFirst().setStreak(4);
        var request=answer(battle,true);var deadline=round(battle).getDeadline();
        assertThatThrownBy(() -> engine.answer(battle,player(battle,0),request,deadline,deadline)).isInstanceOf(com.skillbattles.backend.exception.ConflictException.class);
        assertThat(battle.getState().getPlayers().getFirst().getStreak()).isZero();
        assertThat(round(battle).getAnswers()).allSatisfy(a -> assertThat(a.getPoints()).isZero());
    }
    @Test void fiveCorrectRoundsUseDifficultyBasesAndStreakTableThenWrongResets() {
        var battle=started(5);int[] bases={800,800,1000,1000,1200};int[] bonuses={0,100,150,200,300};
        int expected=0;
        for(int index=0;index<5;index++) {
            round(battle).setBasePoints(bases[index]);send(battle,0,true,1000);
            assertThat(battle.getState().getPlayers().getFirst().getStreak()).isEqualTo(index);
            send(battle,1,false,1000);
            var a=round(battle).getAnswers().getFirst();assertThat(a.getStreakBonus()).isEqualTo(bonuses[index]);
            expected+=bases[index]+180+bonuses[index];assertThat(battle.getState().getPlayers().getFirst().getScore()).isEqualTo(expected);
            engine.advance(battle,round(battle).getRevealEndsAt());
        }
        assertThat(battle.getPhase()).isEqualTo(BattlePhase.FINISHED);
        var wrong=started(1);wrong.getState().getPlayers().getFirst().setStreak(4);send(wrong,0,false,0);send(wrong,1,false,0);
        assertThat(wrong.getState().getPlayers().getFirst().getStreak()).isZero();
        assertThat(round(wrong).getAnswers()).allSatisfy(a -> {assertThat(a.getBasePoints()).isZero();assertThat(a.getSpeedBonus()).isZero();assertThat(a.getStreakBonus()).isZero();});
    }
    private BattleDto overtime() {
        var battle=started(5);var state=battle.getState();state.setOvertimeSeconds(30);
        state.setOvertimeQuestion(waiting(1,BattleMode.PRIVATE,1000,1000).getState().getRounds().getFirst().getQuestion());
        for(int index=0;index<5;index++) {send(battle,0,true,1000);send(battle,1,true,1000);engine.advance(battle,round(battle).getRevealEndsAt());}
        assertThat(battle.getPhase()).isEqualTo(BattlePhase.QUESTION);assertThat(round(battle).isOvertimeRound()).isTrue();
        assertThat(round(battle).getNumber()).isEqualTo(6);assertThat(round(battle).getDeadline()).isEqualTo(round(battle).getStartedAt().plusSeconds(30));
        assertThat(mapper.snapshot(battle,player(battle,0),round(battle).getStartedAt()).getQuestionCount()).isEqualTo(5);
        return battle;
    }
    @ParameterizedTest @CsvSource({"true,1000,true,2000,0","true,2000,true,1000,1","true,1000,false,2000,0","false,1000,true,2000,1","true,1000,true,1000,-1","false,1000,false,2000,-1","true,1000,timeout,0,0","timeout,0,true,2000,1","false,1000,timeout,0,-1","timeout,0,timeout,0,-1"})
    void overtimeWaitsForBothOrDeadlineAndAwardsOnlyOneTieBreakPoint(String first,long t1,String second,long t2,int winner) {
        var battle=overtime();int score=battle.getState().getPlayers().getFirst().getScore();
        List<Integer> order=t1<=t2?List.of(0,1):List.of(1,0);
        for(int id:order) {
            String choice=id==0?first:second;long elapsed=id==0?t1:t2;
            if(!choice.equals("timeout")) {send(battle,id,Boolean.parseBoolean(choice),elapsed);if(round(battle).getAnswers().size()==1) assertThat(battle.getPhase()).isEqualTo(BattlePhase.QUESTION);}
        }
        if(battle.getPhase()==BattlePhase.QUESTION) engine.advance(battle,round(battle).getDeadline());
        assertThat(battle.getPhase()).isEqualTo(BattlePhase.REVEAL);
        for(var a:round(battle).getAnswers()) {
            assertThat(a.getBasePoints()+a.getSpeedBonus()+a.getStreakBonus()).isZero();
            assertThat(a.getPoints()).isEqualTo(a.getTieBreakPoints());
        }
        assertThat(battle.getState().getPlayers()).allSatisfy(p -> assertThat(p.getStreak()).isEqualTo(5));
        engine.advance(battle,round(battle).getRevealEndsAt());
        var result=battle.getResult();assertThat(result.isOvertimePlayed()).isTrue();
        assertThat(result.getReason()).isEqualTo(winner<0?CompletionReason.NORMAL:CompletionReason.OVERTIME_WIN);
        assertThat(result.getWinnerUserId()).isEqualTo(winner<0?null:player(battle,winner));
        assertThat(result.getPlayers().stream().mapToInt(BattleResultPlayerDto::getScore).sum()).isEqualTo(score*2+(winner<0?0:1));
        int version=battle.getVersion();engine.advance(battle,START.plusSeconds(300));assertThat(battle.getVersion()).isEqualTo(version);
    }
    @Test void surrenderInOvertimeDoesNotInventTieBreakPointsAndReplayIsIdempotent() {
        var battle=overtime();Instant at=round(battle).getStartedAt().plusMillis(1);var command=answer(battle,true);
        var receipt=engine.answer(battle,player(battle,0),command,at,at);
        engine.surrender(battle,player(battle,1),at.plusMillis(1));
        assertThat(battle.getResult().getReason()).isEqualTo(CompletionReason.SURRENDER);
        assertThat(round(battle).isCompleted()).isFalse();assertThat(round(battle).getAnswers().getFirst().getTieBreakPoints()).isZero();
        assertThat(engine.answer(battle,player(battle,0),command,at.plusSeconds(1),at.plusSeconds(1))).isEqualTo(receipt);
    }
    @Test void overtimeDisconnectUsesForfeitAndBothOfflineCancelsWithoutElo() {
        var battle=overtime();var first=battle.getState().getPlayers().getFirst();first.setConnected(false);first.setSessionExpiresAt(null);
        first.setReconnectDeadline(round(battle).getStartedAt().plusSeconds(1));engine.advance(battle,first.getReconnectDeadline());
        assertThat(battle.getResult().getReason()).isEqualTo(CompletionReason.DISCONNECT);assertThat(battle.getResult().getWinnerUserId()).isEqualTo(player(battle,1));
        assertThat(round(battle).isCompleted()).isFalse();assertThat(round(battle).getAnswers()).isEmpty();
        var cancelled=overtime();var at=round(cancelled).getStartedAt().plusSeconds(1);
        cancelled.getState().getPlayers().forEach(p -> {p.setConnected(false);p.setSessionExpiresAt(null);p.setReconnectDeadline(at);});engine.advance(cancelled,at);
        assertThat(cancelled.getPhase()).isEqualTo(BattlePhase.CANCELLED);
        assertThat(cancelled.getResult().getReason()).isEqualTo(CompletionReason.BOTH_DISCONNECTED);
        assertThat(cancelled.getResult().getPlayers()).allSatisfy(p -> {assertThat(p.getKFactor()).isZero();assertThat(p.getRatingDelta()).isZero();});
    }
    @ParameterizedTest @CsvSource({"4,64,0","5,32,0","0,64,4"})
    void fifthAndSixthRankedUseIndividualCalibration(int completed,int k,int remaining) {
        var battle=started(1);battle.getState().getPlayers().forEach(p -> p.setCalibrationCompletedMatches(completed));
        engine.surrender(battle,player(battle,1),round(battle).getStartedAt());
        assertThat(battle.getResult().getPlayers()).extracting(BattleResultPlayerDto::getKFactor).containsOnly(k);
        assertThat(battle.getResult().getPlayers()).extracting(BattleResultPlayerDto::getCalibrationMatchesRemaining).containsOnly(remaining);
    }
    @Test void differentKFactorsAreNotZeroSumAndRatingNeverFallsBelowZero() {
        var battle=started(1);battle.getState().getPlayers().getFirst().setCalibrationCompletedMatches(4);
        engine.surrender(battle,player(battle,1),round(battle).getStartedAt());
        assertThat(battle.getResult().getPlayers()).extracting(BattleResultPlayerDto::getRatingDelta).containsExactly(32,-16);
        var floor=started(1);floor.getState().getPlayers().forEach(p -> p.setRating(0));
        engine.surrender(floor,player(floor,0),round(floor).getStartedAt());
        assertThat(floor.getResult().getPlayers().getFirst().getRatingDelta()).isZero();
        assertThat(BattleEngineImpl.eloDelta(1000,1000,0,1)).isEqualTo(-1);
        assertThat(BattleEngineImpl.eloDelta(1000,1000,1,1)).isEqualTo(1);
    }
}
