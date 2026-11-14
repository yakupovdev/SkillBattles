package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;import com.skillbattles.backend.service.*;import com.skillbattles.backend.mapper.*;import com.skillbattles.backend.exception.*;
import lombok.RequiredArgsConstructor;import org.springframework.stereotype.Component;import java.util.*;import java.time.Clock;
@Component @RequiredArgsConstructor public class LeaderboardProcessorImpl implements LeaderboardProcessor {
 private final UserService users;private final RatingProcessor preparation;private final RatingService ratings;private final SeasonService seasons;private final DisciplineService disciplines;private final RankService ranks;private final SubscriptionService subscriptions;private final SeasonMapper mapper;private final UserMapper userMapper;private final Clock clock;
 @Override public LeaderboardResponse get(String code,UUID user){
  try{disciplines.requireActive(code);}catch(ConflictException ex){throw new NotFoundException("DISCIPLINE_NOT_FOUND","Discipline not found.");}
  users.getById(user);var season=seasons.current();preparation.prepare(user,season);
  // A normal read does not visit every account. Only stale-season rating rows need rollover work.
  ratings.rolloverCandidates(code,season.getId()).forEach(id->preparation.prepare(id,season));
  var rows=ratings.leaderboard(code,season.getId(),user);var flags=subscriptions.proFlags(rows.stream().map(LeaderboardRowDto::getUserId).toList());var tiers=ranks.tiers();
  var entries=rows.stream().map(r->new LeaderboardEntry(r.getPosition(),userMapper.toPublicResponse(PublicPlayerDto.builder().id(r.getUserId()).nickname(r.getNickname()).pro(flags.getOrDefault(r.getUserId(),false)).build()),r.getRating(),RankCalculator.fromRating(tiers,r.getRating()).getCode(),r.getCalibrationCompletedMatches()<5)).toList();
  return new LeaderboardResponse(code,mapper.toResponse(season),clock.instant(),entries.stream().filter(r->r.getPosition()<=50).toList(),entries.stream().filter(r->r.getPlayer().getId().equals(user)).findFirst().orElse(null));
 }
}
