package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import java.util.*;
import java.math.*;
/** Uses settled battle snapshots, independently of the history entitlement window. */
public final class StatisticsCalculator {
 private StatisticsCalculator(){}
 public static MatchCountsDto matches(List<BattleDto> history,UUID user,BattleMode mode) {
  var dto=new MatchCountsDto();var sample=new Samples();int current=0,best=0;
  for(var b:history){if(b.getMode()!=mode || b.getPhase()!=BattlePhase.FINISHED)continue;
   dto.setPlayed(dto.getPlayed()+1);UUID winner=b.getResult().getWinnerUserId();
   if(user.equals(winner)){dto.setWins(dto.getWins()+1);current++;best=Math.max(best,current);}
   else {current=0;if(winner==null)dto.setDraws(dto.getDraws()+1);else dto.setLosses(dto.getLosses()+1);}
   collect(b,user,(r,a) -> sample.add(a));
  }
  dto.setCurrentWinStreak(current);dto.setBestWinStreak(best);dto.setWinRatePercent(percent(dto.getWins(),dto.getPlayed()));
  dto.setQuestionCount(sample.count);dto.setAccuracyPercent(percent(sample.correct,sample.count));dto.setAvgAnswerTimeMs(sample.average());return dto;
 }
 public static List<TopicStatsDto> topics(List<BattleDto> history,UUID user) {
  Map<String,Samples> totals=new TreeMap<>();Map<String,String> names=new HashMap<>();
  for(var b:history)collect(b,user,(r,a)->{names.put(r.getQuestion().getTopicCode(),r.getQuestion().getTopicName());totals.computeIfAbsent(r.getQuestion().getTopicCode(),k->new Samples()).add(a);});
  return totals.entrySet().stream().map(e->{var t=new TopicStatsDto();var s=e.getValue();t.setTopicCode(e.getKey());t.setTopicName(names.get(e.getKey()));t.setQuestionCount(s.count);t.setCorrectCount(s.correct);t.setAccuracyPercent(percent(s.correct,s.count));t.setAvgAnswerTimeMs(s.average());t.setWeakTopic(s.count>=5 && s.correct*100L<s.count*65L);return t;}).toList();
 }
 public static List<RatingHistoryPointDto> ratings(List<BattleDto> history,UUID user) {
  var ranked=history.stream().filter(b->b.getMode()==BattleMode.RANKED && b.getPhase()==BattlePhase.FINISHED).toList();
  return ranked.subList(Math.max(0,ranked.size()-30),ranked.size()).stream().map(b->{var p=b.getResult().getPlayers().stream().filter(r->r.getId().equals(user)).findFirst().orElseThrow();var d=new RatingHistoryPointDto();d.setBattleId(b.getId());d.setSeasonId(b.getResult().getSeasonId());d.setFinishedAt(b.getResult().getFinishedAt());d.setRatingBefore(p.getRatingBefore());d.setRatingAfter(p.getRatingAfter());d.setRatingDelta(p.getRatingDelta());return d;}).toList();
 }
 private static void collect(BattleDto battle,UUID user,java.util.function.BiConsumer<BattleRoundDto,BattleAnswerDto> consumer){
  if(battle.getPhase()!=BattlePhase.FINISHED)return;
  for(var r:battle.getState().getRounds())if(r.getStartedAt()!=null){
   var answer=r.getAnswers().stream().filter(a->a.getUserId().equals(user)).findFirst().orElse(null);
   // A completed question includes a no-answer sample. Incomplete forfeits include accepted answers only.
   if(r.isCompleted() || (answer!=null && answer.getSelectedOptionId()!=null && !answer.isTimedOut())) consumer.accept(r,answer);
  }
 }
 private static Double percent(int n,int d){return d==0?null:BigDecimal.valueOf(n).multiply(BigDecimal.valueOf(100)).divide(BigDecimal.valueOf(d),2,RoundingMode.HALF_UP).doubleValue();}
 private static class Samples {int count,correct,submitted;long time;void add(BattleAnswerDto a){count++;if(a!=null){if(a.isCorrect())correct++;if(!a.isTimedOut()&&a.getSelectedOptionId()!=null&&a.getElapsedMs()!=null){submitted++;time+=a.getElapsedMs();}}}Long average(){return submitted==0?null:BigDecimal.valueOf(time).divide(BigDecimal.valueOf(submitted),0,RoundingMode.HALF_UP).longValueExact();}}
}
