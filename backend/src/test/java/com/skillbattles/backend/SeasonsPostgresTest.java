package com.skillbattles.backend;

import com.fasterxml.jackson.databind.*;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.*;
import com.skillbattles.backend.processor.*;
import com.skillbattles.backend.service.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.*;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.*;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.*;
import java.time.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import static com.skillbattles.backend.BattleFixtures.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties={"app.jwt.secret=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=","app.battle.scheduling.enabled=false","app.matchmaking.scheduling.enabled=false","app.season.scheduling.enabled=false"})
@AutoConfigureMockMvc @Import(SeasonsPostgresTest.Config.class) @Testcontainers(disabledWithoutDocker=true)
class SeasonsPostgresTest {
    static final Instant OLD=Instant.parse("2026-12-01T04:59:00Z"), NEW=Instant.parse("2026-12-01T05:00:00Z");
    @Container static final PostgreSQLContainer<?> POSTGRES=new PostgreSQLContainer<>("postgres:17.12-alpine");
    @DynamicPropertySource static void database(DynamicPropertyRegistry r) {r.add("spring.datasource.url",POSTGRES::getJdbcUrl);r.add("spring.datasource.username",POSTGRES::getUsername);r.add("spring.datasource.password",POSTGRES::getPassword);}
    @TestConfiguration static class Config {
        @Bean @Primary MutableClock testClock() {return new MutableClock();}
        @Bean @Primary TestPresence testPresence() {return new TestPresence();}
    }
    @Autowired MutableClock clock;
    @Autowired TestPresence presence;
    @Autowired AuthProcessor auth;
    @Autowired BattleProcessor processor;
    @Autowired BattleService battles;
    @MockitoSpyBean RatingProcessor rollover;
    @Autowired RatingService ratings;
    @MockitoSpyBean SeasonService seasons;
    @Autowired MatchmakingProcessor matchmaking;
    @Autowired QuestionImportProcessor imports;
    @Autowired QuestionImportFileService files;
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @BeforeEach void setup() throws Exception {
        clock.set(OLD);presence.clear();jdbc.execute("TRUNCATE question_reports,ranked_usage, battles,questions,season_archives");uniformTiming(jdbc,10);
        imports.importQuestions(files.read(Path.of(Objects.requireNonNull(getClass().getResource("/fixtures/stage2-questions-test-only.json")).toURI())),false);
    }
    @Test void activeOldRankedSettlesThenArchivesAndRollsExactlyOnceWithoutChangingResult() throws Exception {
        var a=register();var b=register();setRating(a,1801,2001,2101,4);setRating(b,1000,1100,1200,5);
        UUID battle=start(a,b,BattleMode.RANKED);
        clock.set(NEW);
        assertThat(seasons.current().getId()).isEqualTo("WINTER_2026");
        var pending=math(rollover.prepare(id(a)));
        assertThat(pending.isSeasonRolloverPending()).isTrue();assertThat(pending.getRating()).isEqualTo(1801);
        assertThat(pending.getSeasonId()).isEqualTo("FALL_2026");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM season_archives WHERE user_id=? AND discipline_code='SAT_MATH'",Integer.class,id(a))).isZero();
        processor.surrender(battle,id(a));
        var result=processor.result(battle,id(a));var own=result.getPlayers().stream().filter(p -> p.getId().equals(id(a))).findFirst().orElseThrow();
        assertThat(result.getSeasonId()).isEqualTo("FALL_2026");assertThat(own.getKFactor()).isEqualTo(64);
        int expected=java.math.BigDecimal.valueOf(1000).add(java.math.BigDecimal.valueOf(own.getRatingAfter()-1000).multiply(new java.math.BigDecimal("0.5"))).setScale(0,java.math.RoundingMode.HALF_UP).intValueExact();
        var current=math(rollover.prepare(id(a)));assertThat(current.getRating()).isEqualTo(expected);assertThat(current.getSeasonId()).isEqualTo("WINTER_2026");
        assertThat(current.isSeasonRolloverPending()).isFalse();assertThat(current.getCalibrationCompletedMatches()).isEqualTo(5);
        assertThat(current.getAllTimePeakRating()).isEqualTo(2101);assertThat(current.getSeasonPeakRating()).isEqualTo(expected);
        var archive=seasons.history(id(a),"SAT_MATH",0,20).getData().getFirst();
        assertThat(archive.getFinalRating()).isEqualTo(own.getRatingAfter());assertThat(archive.getPeakRating()).isEqualTo(2001);assertThat(archive.getSeasonId()).isEqualTo("FALL_2026");
        String stored=jdbc.queryForObject("SELECT result::text FROM battles WHERE id=?",String.class,battle);
        for(int i=0;i<3;i++) {rollover.prepare(id(a));processor.tick(battle);processor.result(battle,id(a));processor.review(battle,id(a));}
        assertThat(jdbc.queryForObject("SELECT result::text FROM battles WHERE id=?",String.class,battle)).isEqualTo(stored);
        assertThat(math(ratings.getByUserId(id(a))).getRating()).isEqualTo(expected);
        mvc.perform(get("/api/v1/seasons/current").header("Authorization",bearer(a))).andExpect(status().isOk()).andExpect(jsonPath("$.id").value("WINTER_2026"));
        mvc.perform(get("/api/v1/users/me/seasons?disciplineCode=SAT_MATH").header("Authorization",bearer(a)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.pagination.totalElements").value(1)).andExpect(jsonPath("$.data[0].finalRating").value(own.getRatingAfter()));
        mvc.perform(get("/api/v1/users/me/statistics").header("Authorization",bearer(a))).andExpect(status().isOk())
                .andExpect(jsonPath("$.disciplines[0].seasonId").value("WINTER_2026")).andExpect(jsonPath("$.disciplines[0].calibration.completedMatches").value(5));
        assertThat(processor.review(battle,id(a)).getRounds()).isNotEmpty();
        mvc.perform(get("/api/v1/battles/"+battle+"/result").header("Authorization",bearer(a))).andExpect(status().isOk())
                .andExpect(jsonPath("$.players[0].kFactor").value(64)).andExpect(jsonPath("$.players[0].kfactor").doesNotExist())
                .andExpect(jsonPath("$.seasonId").value("FALL_2026")).andExpect(jsonPath("$.rulesVersion").value("0.3"));
    }
    @Test void mixedCalibrationConcurrentFinalizationIncrementsOnceAndPrivateCancelledNeverConsumeIt() throws Exception {
        var a=register();var b=register();setRating(a,1000,1000,1000,4);setRating(b,1000,1000,1000,5);
        UUID battle=start(a,b,BattleMode.RANKED);
        try(var executor=Executors.newFixedThreadPool(2)) {
            var gate=new CountDownLatch(1);
            var first=executor.submit(() -> {gate.await();return processor.surrender(battle,id(b));});
            var second=executor.submit(() -> {gate.await();return processor.surrender(battle,id(b));});gate.countDown();first.get(10,TimeUnit.SECONDS);second.get(10,TimeUnit.SECONDS);
        }
        var result=processor.result(battle,id(a));
        assertThat(result.getPlayers()).extracting(BattleResultPlayerDto::getKFactor).containsExactly(64,32);
        assertThat(result.getPlayers()).extracting(BattleResultPlayerDto::getRatingDelta).containsExactly(32,-16);
        assertThat(math(ratings.getByUserId(id(a))).getCalibrationCompletedMatches()).isEqualTo(5);
        assertThat(math(ratings.getByUserId(id(b))).getCalibrationCompletedMatches()).isEqualTo(6);
        UUID privateBattle=start(a,b,BattleMode.PRIVATE);processor.surrender(privateBattle,id(b));
        assertThat(processor.result(privateBattle,id(a)).getPlayers()).allSatisfy(p -> {assertThat(p.getKFactor()).isZero();assertThat(p.getRatingDelta()).isZero();});
        UUID cancelled=processor.create(new CreateBattleDto(id(a),id(b),"SAT_MATH",BattleMode.RANKED));processor.interrupt(cancelled);
        assertThat(math(ratings.getByUserId(id(a))).getCalibrationCompletedMatches()).isEqualTo(5);
        var sixth=start(a,b,BattleMode.RANKED);processor.surrender(sixth,id(b));
        assertThat(processor.result(sixth,id(a)).getPlayers()).extracting(BattleResultPlayerDto::getKFactor).containsOnly(32);
    }
    @Test void archiveFailureRollsBackSettlementCalibrationAndTerminalBattleTogether() {
        var a=register();var b=register();setRating(a,1801,2000,2100,4);UUID battle=start(a,b,BattleMode.RANKED);clock.set(NEW);
        doAnswer(call -> {call.callRealMethod();throw new IllegalStateException("Test-only archive failure");}).when(seasons).archive(any());
        assertThatThrownBy(() -> processor.surrender(battle,id(a))).isInstanceOf(IllegalStateException.class);
        assertThat(battles.lock(battle).getPhase()).isEqualTo(BattlePhase.QUESTION);
        assertThat(math(ratings.getByUserId(id(a))).getRating()).isEqualTo(1801);
        assertThat(math(ratings.getByUserId(id(a))).getCalibrationCompletedMatches()).isEqualTo(4);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM season_archives",Integer.class)).isZero();
        doCallRealMethod().when(seasons).archive(any());processor.surrender(battle,id(a));
        assertThat(processor.result(battle,id(a)).getSeasonId()).isEqualTo("FALL_2026");
        assertThat(math(ratings.getByUserId(id(a))).getCalibrationCompletedMatches()).isEqualTo(5);
    }
    @Test void privateDoesNotDelayRolloverAndResetDoesNotCreateALifetimePeak() {
        var a=register();var b=register();setRating(a,1,1000,1000,3);UUID battle=start(a,b,BattleMode.PRIVATE);
        clock.set(NEW);var current=math(rollover.prepare(id(a)));
        assertThat(current.getRating()).isEqualTo(501);assertThat(current.getAllTimePeakRating()).isEqualTo(1000);
        assertThat(current.getSeasonPeakRating()).isEqualTo(501);assertThat(current.isSeasonRolloverPending()).isFalse();
        processor.surrender(battle,id(b));assertThat(processor.result(battle,id(a)).getSeasonId()).isNull();
        assertThat(math(ratings.getByUserId(id(a))).getCalibrationCompletedMatches()).isEqualTo(3);
        assertThat(math(ratings.getByUserId(id(a))).getRating()).isEqualTo(501);
    }
    @Test void queuedRatingRollsBeforeMatchingAndSeasonArchivesArePrivatePaginatedAndPersistent() throws Exception {
        var a=register();setRating(a,2000,2100,2200,6);var entry=matchmaking.search(id(a),"SAT_MATH");
        clock.set(NEW);var b=register();setRating(b,1500,1500,1500,0);
        var matched=matchmaking.search(id(b),"SAT_MATH");assertThat(matched.getStatus()).isEqualTo(QueueStatus.MATCHED);
        assertThat(matchmaking.entry(id(a),entry.getId()).getBattleId()).isEqualTo(matched.getBattleId());
        var state=battles.lock(matched.getBattleId()).getState();assertThat(state.getSeasonId()).isEqualTo("WINTER_2026");
        assertThat(state.getPlayers()).extracting(BattlePlayerDto::getRating).containsOnly(1500);
        assertThat(seasons.history(id(a),"SAT_MATH",0,20).getData()).hasSize(1);assertThat(seasons.history(id(b),null,0,20).getData()).isEmpty();
        for(String query:List.of("page=-1","size=101","disciplineCode=UNKNOWN_CODE")) mvc.perform(get("/api/v1/users/me/seasons?"+query).header("Authorization",bearer(a))).andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/users/me/seasons?page=2147483647&size=100").header("Authorization",bearer(a))).andExpect(status().isOk()).andExpect(jsonPath("$.data").isEmpty());
        mvc.perform(get("/api/v1/seasons/current")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/users/me/seasons").header("Authorization","Bearer "+a.getTokens().getRefreshToken())).andExpect(status().isUnauthorized());
    }
    @Test void repeatedSkippedQuarterRolloverPreservesEachFinalAndLifetimeCalibration() {
        var a=register();setRating(a,1801,2000,2100,4);
        clock.set(Instant.parse("2027-06-01T04:00:00Z"));
        rollover.prepare(id(a));rollover.prepare(id(a));
        var history=seasons.history(id(a),"SAT_MATH",0,20).getData();
        assertThat(history).extracting(SeasonArchiveDto::getSeasonId).containsExactly("SPRING_2027","WINTER_2026","FALL_2026");
        assertThat(history).extracting(SeasonArchiveDto::getFinalRating).containsExactly(1201,1401,1801);
        var rating=math(ratings.getByUserId(id(a)));assertThat(rating.getRating()).isEqualTo(1101);assertThat(rating.getCalibrationCompletedMatches()).isEqualTo(4);
        assertThat(rating.getAllTimePeakRating()).isEqualTo(2100);
    }
    @Test void concurrentRolloverWritesOneArchiveAndAppliesOneReset() throws Exception {
        var a=register();setRating(a,1801,2000,2100,4);clock.set(NEW);
        try(var executor=Executors.newFixedThreadPool(2)) {
            var gate=new CountDownLatch(1);
            var first=executor.submit(() -> {gate.await();return rollover.prepare(id(a));});
            var second=executor.submit(() -> {gate.await();return rollover.prepare(id(a));});gate.countDown();
            assertThat(math(first.get(10,TimeUnit.SECONDS)).getRating()).isEqualTo(1401);
            assertThat(math(second.get(10,TimeUnit.SECONDS)).getRating()).isEqualTo(1401);
        }
        assertThat(seasons.history(id(a),"SAT_MATH",0,20).getData()).hasSize(1);
        assertThat(math(ratings.getByUserId(id(a))).getCalibrationCompletedMatches()).isEqualTo(4);
    }
    @Test void overtimeUsesFrozenReserveAndTimingAndPersistsItsTrueScoreAndShownHistory() throws Exception {
        var a=register();var b=register();UUID battle=start(a,b,BattleMode.PRIVATE);
        var reserve=battles.lock(battle).getState().getOvertimeQuestion();
        String key=jdbc.queryForObject("SELECT external_key FROM questions WHERE id=?",String.class,reserve.getId());
        var revised=files.read(Path.of(Objects.requireNonNull(getClass().getResource("/fixtures/stage2-questions-test-only.json")).toURI())).stream().filter(q -> q.getExternalKey().equals(key)).findFirst().orElseThrow();
        revised.setContentVersion(2);revised.setPrompt("TEST ONLY revised reserve after creation");imports.importQuestions(List.of(revised),false);
        jdbc.update("UPDATE disciplines SET overtime_seconds=99 WHERE code='SAT_MATH'");
        try {
            for(int i=0;i<5;i++) {
                var current=battles.lock(battle);clock.set(round(current).getStartedAt().plusSeconds(1));
                processor.answer(battle,id(a),answer(current,true),clock.instant());processor.answer(battle,id(b),answer(current,true),clock.instant());
                if(i==4) assertThat(battles.recentQuestionShows(id(a),"SAT_MATH",5)).hasSize(5);
                clock.set(round(battles.lock(battle)).getRevealEndsAt());processor.tick(battle);
            }
            var state=battles.lock(battle);assertThat(round(state).getQuestion()).isEqualTo(reserve);
            assertThat(round(state).getLimitSeconds()).isEqualTo(30);assertThat(round(state).getNumber()).isEqualTo(6);
            assertThat(battles.recentQuestionShows(id(a),"SAT_MATH",5)).extracting(QuestionSeenDto::getQuestionId).contains(reserve.getId()).hasSize(6);
            clock.set(round(state).getStartedAt().plusSeconds(1));processor.answer(battle,id(a),answer(state,true),clock.instant());
            var hidden=processor.snapshot(battle,id(b));assertThat(hidden.getRound().getReveal()).isNull();
            assertThat(hidden.getPlayers()).extracting(PlayerViewDto::getScore).containsOnly(6450);
            processor.answer(battle,id(b),answer(state,false),clock.instant());clock.set(round(battles.lock(battle)).getRevealEndsAt());processor.tick(battle);
            var result=processor.result(battle,id(a));assertThat(result.getReason()).isEqualTo(CompletionReason.OVERTIME_WIN);
            assertThat(result.getPlayers()).extracting(BattleResultPlayerDto::getScore).containsExactly(6451,6450);
            assertThat(result.getPlayers()).allSatisfy(p -> {assertThat(p.getRatingDelta()).isZero();assertThat(p.getKFactor()).isZero();});
            var review=processor.review(battle,id(a));assertThat(review.getRounds()).hasSize(6);
            assertThat(review.getRounds().get(5).isOvertimeRound()).isTrue();assertThat(review.getRounds().get(5).getQuestion().getPrompt()).isEqualTo(reserve.getPrompt());
            assertThat(review.getRounds().get(5).getAnswers()).extracting(AnswerViewDto::getTieBreakPoints).containsExactly(1,0);
            mvc.perform(get("/api/v1/users/me/battles").header("Authorization",bearer(a))).andExpect(status().isOk()).andExpect(jsonPath("$.data[0].overtimePlayed").value(true));
            mvc.perform(get("/api/v1/battles/"+battle+"/review").header("Authorization",bearer(a))).andExpect(status().isOk()).andExpect(jsonPath("$.rounds[5].isOvertimeRound").value(true));
        } finally {jdbc.update("UPDATE disciplines SET overtime_seconds=30 WHERE code='SAT_MATH'");}
    }
    @Test void legendHasUnboundedRpAndCalibrationIsVisibleWithCurrentEntitlements() throws Exception {
        var a=register();setRating(a,3401,3500,3600,4);
        mvc.perform(get("/api/v1/users/me/statistics").header("Authorization",bearer(a))).andExpect(status().isOk())
                .andExpect(jsonPath("$.disciplines[0].rank.rankCode").value("LEGEND"))
                .andExpect(jsonPath("$.disciplines[0].rank.divisionRpCurrent").value(201))
                .andExpect(jsonPath("$.disciplines[0].rank.divisionRpTarget").isEmpty())
                .andExpect(jsonPath("$.disciplines[0].calibration.isCalibrating").value(true))
                .andExpect(jsonPath("$.disciplines[0].calibration.nextKFactor").value(64))
                .andExpect(jsonPath("$.entitlements.isPro").value(true));
    }
    @Test void catalogueAvailabilityUsesRolledRatingBeforeChoosingAnApplicableGrid() throws Exception {
        var a=register();setRating(a,2800,2800,2800,5);
        jdbc.update("UPDATE questions SET active=false WHERE discipline_code='SAT_MATH' AND difficulty='EASY'");
        mvc.perform(get("/api/v1/battle-modes").header("Authorization",bearer(a))).andExpect(status().isOk()).andExpect(jsonPath("$[0].contentAvailable").value(true));
        clock.set(NEW);
        mvc.perform(get("/api/v1/battle-modes").header("Authorization",bearer(a))).andExpect(status().isOk()).andExpect(jsonPath("$[0].contentAvailable").value(false));
        assertThat(math(ratings.getByUserId(id(a))).getRating()).isEqualTo(1900);
    }
    @Test void quarterBoundaryWhilePreparingPairCannotMixFrozenSeasonsOrRatings() {
        var a=register();var b=register();setRating(a,1801,1801,1801,0);setRating(b,1801,1801,1801,0);
        var moved=new java.util.concurrent.atomic.AtomicBoolean();
        doAnswer(call -> {var result=call.callRealMethod();if(moved.compareAndSet(false,true)) clock.set(NEW);return result;})
                .when(rollover).prepare(any(UUID.class),any(SeasonDto.class));
        UUID battle=start(a,b,BattleMode.RANKED);var state=battles.lock(battle).getState();
        assertThat(state.getSeasonId()).isEqualTo("FALL_2026");assertThat(state.getPlayers()).extracting(BattlePlayerDto::getRating).containsOnly(1801);
        assertThat(math(ratings.getByUserId(id(a))).getSeasonId()).isEqualTo("FALL_2026");
        assertThat(math(ratings.getByUserId(id(b))).getSeasonId()).isEqualTo("FALL_2026");
        processor.surrender(battle,id(b));assertThat(processor.result(battle,id(a)).getSeasonId()).isEqualTo("FALL_2026");
        assertThat(math(ratings.getByUserId(id(a))).getSeasonId()).isEqualTo("WINTER_2026");
    }
    private void setRating(AuthDto user,int rating,int peak,int allTime,int completed) {jdbc.update("UPDATE ratings SET rating=?,season_peak_rating=?,all_time_peak_rating=?,calibration_completed_matches=? WHERE user_id=? AND discipline_code='SAT_MATH'",rating,peak,allTime,completed,id(user));}
    private RatingDto math(List<RatingDto> values) {return values.stream().filter(r -> r.getDisciplineCode().equals("SAT_MATH")).findFirst().orElseThrow();}
    private UUID start(AuthDto a,AuthDto b,BattleMode mode) {
        presence.connect(id(a),clock.instant());presence.connect(id(b),clock.instant());
        UUID battle=processor.create(new CreateBattleDto(id(a),id(b),"SAT_MATH",mode));processor.ready(battle,id(a));processor.ready(battle,id(b));
        clock.set(clock.instant().plusSeconds(3));processor.tick(battle);return battle;
    }
    private UUID id(AuthDto user) {return user.getUser().getId();}
    private String bearer(AuthDto user) {return "Bearer "+user.getTokens().getAccessToken();}
    private AuthDto register() {var dto=new RegisterDto(); dto.setBirthYear(2000); dto.setBirthMonth(1);String suffix=UUID.randomUUID().toString().replace("-","").substring(0,12);dto.setEmail(suffix+"@example.com");dto.setNickname("Season_"+suffix);dto.setPassword("ExamplePass123!");return auth.register(dto);}
}
