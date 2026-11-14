package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;import com.skillbattles.backend.entity.*;import org.junit.jupiter.api.*;import java.util.*;import static org.assertj.core.api.Assertions.*;import static com.skillbattles.backend.BattleFixtures.*;
class StatisticsCalculatorTest {
 @Test void noDataIsNullNotFabricatedZero(){var s=StatisticsCalculator.matches(List.of(),UUID.randomUUID(),BattleMode.RANKED);assertThat(s.getPlayed()).isZero();assertThat(s.getWinRatePercent()).isNull();assertThat(s.getAccuracyPercent()).isNull();assertThat(s.getAvgAnswerTimeMs()).isNull();}
 @Test void samplingIncludesTimeoutAndOvertimeButOnlyAcceptedIncompleteAnswers(){
  var b=waiting(4,BattleMode.RANKED,1000,1000);var user=player(b,0);b.setPhase(BattlePhase.FINISHED);var result=new BattleResultDataDto();result.setWinnerUserId(user);b.setResult(result);
  for(var r:b.getState().getRounds())r.setStartedAt(START);
  var rounds=b.getState().getRounds();rounds.get(0).setCompleted(true);rounds.get(1).setCompleted(true);rounds.get(1).setOvertimeRound(true);
  rounds.get(0).getAnswers().add(answerFor(user,true,1000L)); // completed correct
  // second completed question is a timeout even if no answer entry was materialized
  rounds.get(2).getAnswers().add(answerFor(user,false,2000L)); // accepted incomplete
  var s=StatisticsCalculator.matches(List.of(b),user,BattleMode.RANKED);
  assertThat(s.getQuestionCount()).isEqualTo(3);assertThat(s.getAccuracyPercent()).isEqualTo(33.33);assertThat(s.getAvgAnswerTimeMs()).isEqualTo(1500);assertThat(s.getWinRatePercent()).isEqualTo(100);
  var topics=StatisticsCalculator.topics(List.of(b),user);assertThat(topics).hasSize(1);assertThat(topics.getFirst().isWeakTopic()).isFalse();
 }
 @Test void cancelledExcludedAndLossOrDrawBreaksWinningStreak(){
  var b=waiting(1,BattleMode.RANKED,1000,1000);var u=player(b,0);b.setPhase(BattlePhase.FINISHED);b.setResult(new BattleResultDataDto());b.getResult().setWinnerUserId(u);
  var loss=waiting(1,BattleMode.RANKED,1000,1000);loss.setPhase(BattlePhase.FINISHED);loss.setResult(new BattleResultDataDto());loss.getResult().setWinnerUserId(UUID.randomUUID());
  var cancelled=waiting(1,BattleMode.RANKED,1000,1000);cancelled.setPhase(BattlePhase.CANCELLED);
  var s=StatisticsCalculator.matches(List.of(b,b,loss,b,cancelled),u,BattleMode.RANKED);assertThat(s.getPlayed()).isEqualTo(4);assertThat(s.getCurrentWinStreak()).isEqualTo(1);assertThat(s.getBestWinStreak()).isEqualTo(2);assertThat(s.getWinRatePercent()).isEqualTo(75);
 }
 @Test void weakThresholdUsesUnroundedAccuracyAndAtLeastFiveSamples(){
  var b=waiting(5,BattleMode.PRIVATE,1000,1000);var u=player(b,0);b.setPhase(BattlePhase.FINISHED);b.setResult(new BattleResultDataDto());
  for(var r:b.getState().getRounds()){r.setStartedAt(START);r.setCompleted(true);r.getAnswers().add(answerFor(u,false,1L));}
  assertThat(StatisticsCalculator.topics(List.of(b),u).getFirst().isWeakTopic()).isTrue();
 }
 @Test void ratingGraphContainsOnlyLastThirtyRankedResultsInChronologicalOrder(){
  var user=UUID.randomUUID();var history=new ArrayList<BattleDto>();
  for(int i=0;i<40;i++){
   var b=waiting(1,BattleMode.RANKED,1000,1000);b.setPhase(BattlePhase.FINISHED);var result=new BattleResultDataDto();result.setSeasonId("FALL_2026");result.setFinishedAt(START.plusSeconds(i));
   var p=new BattleResultPlayerDto();p.setId(user);p.setRatingBefore(1000+i);p.setRatingAfter(1001+i);p.setRatingDelta(1);result.setPlayers(List.of(p));b.setResult(result);history.add(b);
  }
  var points=StatisticsCalculator.ratings(history,user);assertThat(points).hasSize(30);assertThat(points.getFirst().getRatingBefore()).isEqualTo(1010);assertThat(points.getLast().getRatingAfter()).isEqualTo(1040);assertThat(points).allMatch(p->p.getSeasonId().equals("FALL_2026")&&p.getRatingDelta()==1);
 }
 BattleAnswerDto answerFor(UUID user,boolean correct,Long ms){var a=new BattleAnswerDto();a.setUserId(user);a.setCorrect(correct);a.setSelectedOptionId(UUID.randomUUID());a.setElapsedMs(ms);return a;}
}
