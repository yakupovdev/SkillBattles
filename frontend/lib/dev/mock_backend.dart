import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';

import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';
import 'package:skill_battles/core/utils/time/clock.dart';
import 'package:skill_battles/dev/dev_scenario.dart';
import 'package:skill_battles/dev/mock_content.dart';
import 'package:skill_battles/features/auth/domain/entity/age_check_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/age_check_result.dart';
import 'package:skill_battles/features/auth/domain/usecases/check_age_usecase.dart';

/// DEVELOPMENT ONLY — an in-memory imitation of the v0.3 API so the UI can
/// be exercised without the backend (`--dart-define=DEV_MOCKS=true`).
///
/// It follows the contract's rules closely enough for UI work (phases,
/// scoring, overtime, Elo, Free/Pro gating, quota, billing states) but it is
/// not the source of truth and never replaces an end-to-end check.
final class MockBackend {
  MockBackend({required this._clock});

  final Clock _clock;
  final DevScenario scenario = DevScenario();
  final math.Random _random = math.Random(7);
  final StreamController<RealtimeEnvelope> _events =
      StreamController<RealtimeEnvelope>.broadcast();

  /// Personal events, as the STOMP subscription would deliver them.
  Stream<RealtimeEnvelope> get events => _events.stream;

  static const int _freeLimit = 5;
  static const String _seasonId = 'FALL_2026';

  int _ids = 0;
  String _id() {
    _ids++;
    final String hex = _ids.toRadixString(16).padLeft(12, '0');
    return '00000000-0000-4000-8000-$hex';
  }

  DateTime get _now => _clock.now().toUtc();

  // ---------------------------------------------------------------- account

  _MockUser? _user;
  bool _signedIn = false;
  int _tokenSerial = 0;
  bool _isPro = false;
  String _plan = 'FREE';
  String _subscriptionStatus = 'NONE';
  DateTime? _periodEnd;
  bool _cancelAtPeriodEnd = false;
  int _entitlementVersion = 1;
  int _accountVersion = 0;
  int _rankedToday = 0;
  final Map<String, int> _rating = <String, int>{
    for (final String code in MockContent.disciplines) code: 1000,
  };
  final Map<String, int> _calibrated = <String, int>{
    for (final String code in MockContent.disciplines) code: 0,
  };
  final Map<String, int> _peak = <String, int>{
    for (final String code in MockContent.disciplines) code: 1000,
  };
  final List<_MockBattle> _finished = <_MockBattle>[];
  final Set<String> _qualifiedDays = <String>{};
  final Map<String, Map<String, dynamic>> _reports =
      <String, Map<String, dynamic>>{};

  String? _lastResetToken;

  /// The link a reset e-mail would contain (shown in the dev panel).
  String? get lastResetLink =>
      _lastResetToken == null ? null : '/auth/reset?token=$_lastResetToken';

  // ------------------------------------------------------------- activities

  _MockQueue? _queue;
  _MockDuel? _duel;
  _MockBattle? _live;
  final Map<String, _MockRematch> _rematches = <String, _MockRematch>{};
  final Map<String, _MockBattle> _battles = <String, _MockBattle>{};

  void dispose() {
    for (final _MockBattle battle in _battles.values) {
      battle.cancelTimers();
    }
    _events.close();
  }

  // ---------------------------------------------------------- dev controls

  /// Simulates a verified webhook that changes the plan.
  void setPro(bool isPro, {String plan = 'PRO_MONTHLY'}) {
    _isPro = isPro;
    _plan = isPro ? plan : 'FREE';
    _subscriptionStatus = isPro ? 'ACTIVE' : 'NONE';
    _periodEnd = isPro ? _now.add(const Duration(days: 30)) : null;
    _cancelAtPeriodEnd = false;
    _entitlementVersion++;
    _emitAccount();
  }

  /// The paid period ended: Free rules apply again at once.
  void expireSubscription() {
    if (_subscriptionStatus == 'NONE') return;
    _isPro = false;
    _subscriptionStatus = 'EXPIRED';
    _entitlementVersion++;
    _emitAccount();
  }

  /// Uses (or frees) today's Free ranked attempts.
  void setDailyLimitReached(bool reached) {
    _rankedToday = reached ? _freeLimit : 0;
    _emitAccount();
  }

  bool get isPro => _isPro;
  bool get dailyLimitReached => _rankedToday >= _freeLimit;

  // --------------------------------------------------------------- routing

  Future<Object?> handle(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final Map<String, dynamic> data = body is Map<String, dynamic>
        ? body
        : <String, dynamic>{};
    final List<String> s = path
        .split('/')
        .where((String p) => p.isNotEmpty)
        .toList();
    final String route = '$method ${s.join('/')}';

    // Public routes.
    switch (route) {
      case 'POST auth/register':
        return _register(data);
      case 'POST auth/login':
        return _login(data);
      case 'POST auth/refresh':
        if (!_signedIn) throw _error(401, 'UNAUTHORIZED', 'Session expired.');
        return _auth();
      case 'POST auth/logout':
        _signedIn = false;
        return null;
      case 'POST auth/password-reset/request':
        _lastResetToken = 'mock-reset-${_id()}-${_now.millisecondsSinceEpoch}';
        return <String, dynamic>{
          'message':
              'If an account exists, password reset instructions will be sent.',
        };
      case 'POST auth/password-reset/confirm':
        if (data['token'] != _lastResetToken || _lastResetToken == null) {
          throw _error(
            400,
            'INVALID_RESET_TOKEN',
            'The reset link is invalid.',
          );
        }
        _lastResetToken = null;
        _signedIn = false;
        return null;
      case 'GET subscriptions/plans':
        return MockContent.plans();
    }

    if (!_signedIn || _user == null) {
      throw _error(401, 'UNAUTHORIZED', 'Authentication is required.');
    }

    switch (route) {
      case 'GET users/me':
        return _userJson();
      case 'PATCH users/me':
        return _updateProfile(data);
      case 'GET users/me/statistics':
        return _statistics();
      case 'GET users/me/limits':
        return _limits();
      case 'GET users/me/activity':
        return _activity();
      case 'GET users/me/seasons':
        return _seasons(query?['disciplineCode'] as String?);
      case 'GET users/me/battles':
        return _history(query ?? const <String, dynamic>{});
      case 'GET battle-modes':
        return MockContent.disciplines.map(MockContent.battleMode).toList();
      case 'GET ranks':
        return MockContent.rankTiers();
      case 'GET seasons/current':
        return _season();
      case 'POST matchmaking/entries':
        return _joinQueue(data['disciplineCode'] as String);
      case 'POST duels':
        return _createDuel(data['disciplineCode'] as String);
      case 'POST duels/join':
        return _joinDuel(data['code'] as String);
      case 'GET subscriptions/me':
        return _subscriptionJson();
      case 'POST subscriptions/checkout':
        return _checkout(data);
      case 'POST subscriptions/portal':
        if (_subscriptionStatus == 'NONE') {
          throw _error(
            409,
            'BILLING_CUSTOMER_NOT_FOUND',
            'No billing profile.',
          );
        }
        return <String, dynamic>{'url': '/pro'};
    }

    if (s.length >= 3 && s[0] == 'matchmaking') {
      final _MockQueue queue = _ownQueue(s[2]);
      if (method == 'GET') return queue.toJson();
      if (method == 'DELETE') return _cancelQueue(queue);
    }
    if (s.length == 2 && s[0] == 'duels') {
      final _MockDuel duel = _ownDuel(s[1]);
      if (method == 'GET') return duel.toJson();
      if (method == 'DELETE') return _cancelDuel(duel);
    }
    if (s.length >= 2 && s[0] == 'leaderboards') return _leaderboard(s[1]);
    if (s.length >= 2 && s[0] == 'battles') {
      final _MockBattle battle =
          _battles[s[1]] ??
          (throw _error(404, 'BATTLE_NOT_FOUND', 'Battle not found.'));
      final String action = s.length > 2 ? s.sublist(2).join('/') : '';
      return _battleRoute(method, action, battle, data, query);
    }
    throw _error(404, 'NOT_FOUND', 'Unknown mock route $route.');
  }

  // ------------------------------------------------------------------ auth

  Map<String, dynamic> _register(Map<String, dynamic> data) {
    final AgeCheckResult age = CheckAgeUsecase(_clock)(
      AgeCheckParamsEntity(
        birthYear: data['birthYear'] as int,
        birthMonth: data['birthMonth'] as int,
        birthDay: data['birthDay'] as int?,
      ),
    );
    switch (age) {
      case AgeCheckResult.restricted:
        throw _error(
          403,
          'AGE_RESTRICTED',
          'SkillBattles is available from age 13.',
        );
      case AgeCheckResult.needsDay:
        throw _error(
          400,
          'VALIDATION_ERROR',
          'The day of birth is required.',
          fieldErrors: <String, String>{'birthDay': 'Enter your day of birth.'},
        );
      case AgeCheckResult.invalidDate:
        throw _error(400, 'VALIDATION_ERROR', 'Enter a valid date of birth.');
      case AgeCheckResult.eligible:
        break;
    }
    final String nickname = data['nickname'] as String;
    if (nickname.toLowerCase() == 'taken') {
      throw _error(
        409,
        'NICKNAME_ALREADY_EXISTS',
        'This nickname is already taken.',
        fieldErrors: <String, String>{'nickname': 'This nickname is taken.'},
      );
    }
    _user = _MockUser(
      id: _id(),
      email: data['email'] as String,
      nickname: nickname,
      createdAt: _now,
    );
    _signedIn = true;
    return _auth();
  }

  Map<String, dynamic> _login(Map<String, dynamic> data) {
    final String email = data['email'] as String;
    if ((data['password'] as String) == 'wrongpass') {
      throw _error(
        401,
        'INVALID_CREDENTIALS',
        'Email or password is incorrect.',
      );
    }
    _user ??= _MockUser(
      id: _id(),
      email: email,
      nickname: email
          .split('@')
          .first
          .replaceAll(RegExp('[^A-Za-z0-9_-]'), '_'),
      createdAt: _now.subtract(const Duration(days: 40)),
    );
    _signedIn = true;
    return _auth();
  }

  Map<String, dynamic> _auth() {
    _tokenSerial++;
    return <String, dynamic>{
      'accessToken': 'mock-access-$_tokenSerial',
      'refreshToken': 'mock-refresh-$_tokenSerial',
      'tokenType': 'Bearer',
      'accessExpiresIn': 900,
      'refreshExpiresIn': 604800,
      'user': _userJson(),
    };
  }

  Map<String, dynamic> _userJson() => <String, dynamic>{
    'id': _user!.id,
    'email': _user!.email,
    'nickname': _user!.nickname,
    'createdAt': _iso(_user!.createdAt),
    'isPro': _isPro,
  };

  Map<String, dynamic> _updateProfile(Map<String, dynamic> data) {
    if (data.isEmpty) throw _error(400, 'EMPTY_UPDATE', 'Nothing to update.');
    bool passwordChanged = false;
    if (data['newPassword'] != null) {
      if (data['currentPassword'] == 'wrongpass') {
        throw _error(
          401,
          'INVALID_CURRENT_PASSWORD',
          'The current password is incorrect.',
        );
      }
      passwordChanged = true;
    }
    final Object? nickname = data['nickname'];
    if (nickname is String) {
      if (nickname.toLowerCase() == 'taken') {
        throw _error(
          409,
          'NICKNAME_ALREADY_EXISTS',
          'This nickname is already taken.',
        );
      }
      _user = _user!.copyWith(nickname: nickname);
    }
    final Map<String, dynamic> response = <String, dynamic>{
      'user': _userJson(),
      'passwordChanged': passwordChanged,
      'reauthenticationRequired': passwordChanged,
    };
    if (passwordChanged) _signedIn = false;
    return response;
  }

  // ----------------------------------------------------- limits and rights

  Map<String, dynamic> _entitlements() => <String, dynamic>{
    'isPro': _isPro,
    'version': _entitlementVersion,
    'unlimitedRanked': _isPro,
    'historyMatchLimit': _isPro ? null : 10,
    'canViewCorrectAnswers': _isPro,
    'canViewExplanations': _isPro,
    'canViewAdvancedAnalytics': _isPro,
    'canFilterMistakes': _isPro,
  };

  DateTime get _nextEtMidnight {
    final DateTime now = _now;
    final DateTime etNow = now.subtract(const Duration(hours: 5));
    final DateTime etMidnight = DateTime.utc(
      etNow.year,
      etNow.month,
      etNow.day + 1,
    );
    return etMidnight.add(const Duration(hours: 5));
  }

  Map<String, dynamic> _limits() => <String, dynamic>{
    'planCode': _isPro ? _plan : 'FREE',
    'timezone': 'America/New_York',
    'date': _date(_now.subtract(const Duration(hours: 5))),
    'freeRankedLimit': _freeLimit,
    'rankedStartedToday': _rankedToday,
    'freeRankedRemaining': _isPro
        ? null
        : math.max(0, _freeLimit - _rankedToday),
    'resetsAt': _iso(_nextEtMidnight),
    'canStartRanked': _isPro || _rankedToday < _freeLimit,
    'entitlements': _entitlements(),
  };

  bool get _canStartRanked => _isPro || _rankedToday < _freeLimit;

  ApiDioError _limitError() => _error(
    429,
    'DAILY_LIMIT_REACHED',
    'You have used all 5 free ranked matches for today.',
    resetsAt: _nextEtMidnight,
  );

  Map<String, dynamic> _subscriptionJson() => <String, dynamic>{
    'planCode': _isPro
        ? _plan
        : (_subscriptionStatus == 'NONE' ? 'FREE' : _plan),
    'status': _subscriptionStatus,
    'billingMode': 'TEST',
    'currentPeriodStart': _periodEnd == null
        ? null
        : _iso(_periodEnd!.subtract(const Duration(days: 30))),
    'currentPeriodEnd': _periodEnd == null ? null : _iso(_periodEnd!),
    'cancelAtPeriodEnd': _cancelAtPeriodEnd,
    'entitlements': _entitlements(),
  };

  Map<String, dynamic> _checkout(Map<String, dynamic> data) {
    if (_isPro) {
      throw _error(
        409,
        'SUBSCRIPTION_ALREADY_ACTIVE',
        'Pro is already active.',
      );
    }
    final String plan = data['planCode'] as String;
    _plan = plan;
    _subscriptionStatus = 'INCOMPLETE';
    Timer(const Duration(milliseconds: 2500), () {
      if (scenario.payment == DevPayment.activates) {
        setPro(true, plan: plan);
      } else {
        _emitAccount();
      }
    });
    return <String, dynamic>{
      'checkoutSessionId': 'cs_test_mock_${_id()}',
      'url': '/billing/return?success=true',
      'expiresAt': _iso(_now.add(const Duration(minutes: 30))),
    };
  }

  Map<String, dynamic> _streaks() {
    final DateTime today = _now.subtract(const Duration(hours: 5));
    int daily = 0;
    for (int i = 0; ; i++) {
      final String key = _date(today.subtract(Duration(days: i)));
      if (_qualifiedDays.contains(key)) {
        daily++;
      } else if (i > 0 || daily > 0) {
        break;
      } else {
        continue;
      }
      if (i > 400) break;
    }
    final DateTime weekStart = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    int weekDays = 0;
    for (int i = 0; i < 7; i++) {
      if (_qualifiedDays.contains(_date(weekStart.add(Duration(days: i))))) {
        weekDays++;
      }
    }
    return <String, dynamic>{
      'timezone': 'America/New_York',
      'dailyCurrent': daily,
      'dailyBest': math.max(daily, 3),
      'lastQualifiedDate': _qualifiedDays.isEmpty
          ? null
          : (_qualifiedDays.toList()..sort()).last,
      'weeklyCurrent': weekDays >= 4 ? 1 : 0,
      'weeklyBest': 1,
      'currentWeekStart': _date(weekStart),
      'currentWeekActiveDays': weekDays,
      'currentWeekTarget': 4,
    };
  }

  void _emitAccount() {
    if (_user == null) return;
    _accountVersion++;
    _emit(
      RealtimeEventType.accountChanged,
      _user!.id,
      _accountVersion,
      <String, dynamic>{
        'user': _userJson(),
        'subscription': _subscriptionJson(),
        'limits': _limits(),
        'streaks': _streaks(),
      },
    );
  }

  // ------------------------------------------------------------ statistics

  Map<String, dynamic> _matchStats(Iterable<_MockBattle> battles) {
    int wins = 0, losses = 0, draws = 0, current = 0, best = 0;
    int questions = 0, correct = 0, timeSum = 0, timeCount = 0;
    for (final _MockBattle b in battles) {
      if (b.status != 'FINISHED') continue;
      final String outcome = b.outcomeFor(_user!.id);
      if (outcome == 'WIN') {
        wins++;
        current++;
        best = math.max(best, current);
      } else {
        outcome == 'LOSS' ? losses++ : draws++;
        current = 0;
      }
      for (final _MockRound r in b.rounds.where((_MockRound r) => r.revealed)) {
        final _MockAnswer? a = r.answers[_user!.id];
        questions++;
        if (a != null && a.correct) correct++;
        if (a != null && a.elapsedMs != null) {
          timeSum += a.elapsedMs!;
          timeCount++;
        }
      }
    }
    final int played = wins + losses + draws;
    double? pct(int a, int b) =>
        b == 0 ? null : (a / b * 10000).roundToDouble() / 100;
    return <String, dynamic>{
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'played': played,
      'winRatePercent': pct(wins, played),
      'currentWinStreak': current,
      'bestWinStreak': best,
      'accuracyPercent': pct(correct, questions),
      'avgAnswerTimeMs': timeCount == 0 ? null : timeSum ~/ timeCount,
      'questionCount': questions,
    };
  }

  Map<String, dynamic> _statistics() => <String, dynamic>{
    'entitlements': _entitlements(),
    'streaks': _streaks(),
    'disciplines': <Map<String, dynamic>>[
      for (final String code in MockContent.disciplines) _disciplineStats(code),
    ],
  };

  Map<String, dynamic> _disciplineStats(String code) {
    final Iterable<_MockBattle> mine = _finished.where(
      (_MockBattle b) => b.discipline == code,
    );
    final int completed = _calibrated[code]!;
    final List<Map<String, dynamic>> topics = <Map<String, dynamic>>[];
    final Map<String, List<int>> byTopic = <String, List<int>>{};
    final Map<String, String> names = <String, String>{};
    for (final _MockBattle b in mine) {
      for (final _MockRound r in b.rounds.where((_MockRound r) => r.revealed)) {
        final List<int> agg = byTopic.putIfAbsent(
          r.topicCode,
          () => <int>[0, 0],
        );
        names[r.topicCode] = r.topicName;
        agg[0]++;
        if (r.answers[_user!.id]?.correct ?? false) agg[1]++;
      }
    }
    byTopic.forEach((String topic, List<int> agg) {
      final double accuracy = (agg[1] / agg[0] * 10000).roundToDouble() / 100;
      topics.add(<String, dynamic>{
        'topicCode': topic,
        'topicName': names[topic],
        'questionCount': agg[0],
        'correctCount': agg[1],
        'accuracyPercent': accuracy,
        'avgAnswerTimeMs': null,
        'isWeakTopic': accuracy < 65 && agg[0] >= 5,
      });
    });
    final List<Map<String, dynamic>> history = <Map<String, dynamic>>[
      for (final _MockBattle b in mine.where(
        (_MockBattle b) => b.mode == 'RANKED' && b.status == 'FINISHED',
      ))
        <String, dynamic>{
          'battleId': b.id,
          'seasonId': _seasonId,
          'finishedAt': _iso(b.finishedAt!),
          'ratingBefore': b.me.rating,
          'ratingAfter': b.me.rating + b.myDelta,
          'ratingDelta': b.myDelta,
        },
    ];
    final int rating = _rating[code]!;
    return <String, dynamic>{
      'disciplineCode': code,
      'rating': rating,
      'rank': MockContent.rankProgress(rating),
      'calibration': <String, dynamic>{
        'completedMatches': completed,
        'matchesRemaining': math.max(0, 5 - completed),
        'isCalibrating': completed < 5,
        'nextKFactor': completed < 5 ? 64 : 32,
      },
      'allTimePeakRating': _peak[code],
      'allTimePeakRankCode': MockContent.rankCode(_peak[code]!),
      'seasonId': _seasonId,
      'seasonPeakRating': _peak[code],
      'seasonPeakRankCode': MockContent.rankCode(_peak[code]!),
      'seasonRolloverPending': false,
      'ranked': _matchStats(mine.where((_MockBattle b) => b.mode == 'RANKED')),
      'privateMatches': _matchStats(
        mine.where((_MockBattle b) => b.mode == 'PRIVATE'),
      ),
      'topicStats': _isPro ? topics : null,
      'ratingHistory': _isPro ? history.reversed.take(30).toList() : null,
    };
  }

  Map<String, dynamic> _season() => <String, dynamic>{
    'id': _seasonId,
    'name': 'Fall 2026',
    'startsAt': '2026-09-01T04:00:00Z',
    'endsAt': '2026-12-01T05:00:00Z',
    'timezone': 'America/New_York',
  };

  Map<String, dynamic> _seasons(String? discipline) {
    final List<Map<String, dynamic>> data = <Map<String, dynamic>>[
      for (final String code in MockContent.disciplines)
        if (discipline == null || discipline == code)
          <String, dynamic>{
            'season': <String, dynamic>{
              'id': 'SUMMER_2026',
              'name': 'Summer 2026',
              'startsAt': '2026-06-01T04:00:00Z',
              'endsAt': '2026-09-01T04:00:00Z',
              'timezone': 'America/New_York',
            },
            'disciplineCode': code,
            'peakRating': 1140,
            'peakRankCode': 'SILVER_II',
            'finalRating': 1080,
          },
    ];
    return <String, dynamic>{
      'data': data,
      'pagination': _pagination(0, 20, data.length),
    };
  }

  Map<String, dynamic> _pagination(int page, int size, int total) =>
      <String, dynamic>{
        'page': page,
        'size': size,
        'totalElements': total,
        'totalPages': total == 0 ? 0 : (total + size - 1) ~/ size,
      };

  /// Latest first, cut to 10 for Free *before* filtering.
  List<_MockBattle> get _visibleHistory {
    final List<_MockBattle> sorted = <_MockBattle>[..._finished]
      ..sort(
        (_MockBattle a, _MockBattle b) =>
            b.finishedAt!.compareTo(a.finishedAt!),
      );
    return _isPro ? sorted : sorted.take(10).toList();
  }

  bool _canOpen(_MockBattle battle) =>
      !battle.isTerminal || _visibleHistory.contains(battle);

  Map<String, dynamic> _history(Map<String, dynamic> query) {
    final int page = query['page'] as int? ?? 0;
    final int size = query['size'] as int? ?? 20;
    final String? mode = query['mode'] as String?;
    final String? discipline = query['disciplineCode'] as String?;
    List<_MockBattle> items = _visibleHistory
        .where((_MockBattle b) => mode == null || b.mode == mode)
        .where(
          (_MockBattle b) => discipline == null || b.discipline == discipline,
        )
        .toList();
    if (query['sort'] == 'createdAt,asc') items = items.reversed.toList();
    final List<_MockBattle> slice = items.skip(page * size).take(size).toList();
    return <String, dynamic>{
      'data': <Map<String, dynamic>>[
        for (final _MockBattle b in slice)
          <String, dynamic>{
            'battleId': b.id,
            'disciplineCode': b.discipline,
            'format': 'STANDARD',
            'mode': b.mode,
            'outcome': b.outcomeFor(_user!.id),
            'reason': b.reason,
            'opponent': b.bot.publicJson(),
            'myScore': b.me.score,
            'opponentScore': b.bot.score,
            'ratingDelta': b.myDelta,
            'seasonId': b.mode == 'RANKED' ? _seasonId : null,
            'overtimePlayed': b.overtimePlayed,
            'createdAt': _iso(b.createdAt),
            'finishedAt': _iso(b.finishedAt!),
          },
      ],
      'pagination': _pagination(page, size, items.length),
      'historyLimit': _isPro ? null : 10,
    };
  }

  Map<String, dynamic> _leaderboard(String code) {
    if (!MockContent.disciplines.contains(code)) {
      throw _error(404, 'DISCIPLINE_NOT_FOUND', 'Unknown discipline.');
    }
    final List<(String, String, int, bool)> rows =
        <(String, String, int, bool)>[
          for (int i = 0; i < 14; i++)
            (
              'bot-$i',
              _botNames[i % _botNames.length],
              1480 - i * 37,
              i % 4 == 0,
            ),
          (_user!.id, _user!.nickname, _rating[code]!, _isPro),
        ]..sort((a, b) => b.$3.compareTo(a.$3));
    Map<String, dynamic> entry(int index) => <String, dynamic>{
      'position': index + 1,
      'player': <String, dynamic>{
        'id': rows[index].$1.startsWith('bot')
            ? _botId(rows[index].$1)
            : rows[index].$1,
        'nickname': rows[index].$2,
        'isPro': rows[index].$4,
      },
      'rating': rows[index].$3,
      'rankCode': MockContent.rankCode(rows[index].$3),
      'isCalibrating': rows[index].$1 == _user!.id && _calibrated[code]! < 5,
    };
    final int myIndex = rows.indexWhere((r) => r.$1 == _user!.id);
    return <String, dynamic>{
      'disciplineCode': code,
      'season': _season(),
      'generatedAt': _iso(_now),
      'top': <Map<String, dynamic>>[
        for (int i = 0; i < rows.length; i++) entry(i),
      ],
      'me': entry(myIndex),
    };
  }

  final Map<String, String> _botIds = <String, String>{};
  String _botId(String key) => _botIds.putIfAbsent(key, _id);

  static const List<String> _botNames = <String>[
    'Sam_Two',
    'nova_k',
    'Mira-9',
    'ezra_q',
    'lin_codes',
    'Theo_W',
    'ada_92',
  ];

  // ------------------------------------------------------------- activity

  Map<String, dynamic> _activity() {
    final _MockBattle? live = _live;
    if (live != null && !live.isTerminal) {
      return _activityJson('BATTLE', live.id, live.id, 'BATTLE');
    }
    final _MockQueue? queue = _queue;
    if (queue != null && queue.status == 'SEARCHING') {
      return _activityJson('QUEUE', queue.id, null, 'QUEUE_ENTRY');
    }
    final _MockDuel? duel = _duel;
    if (duel != null && duel.status == 'WAITING') {
      return _activityJson('PRIVATE_DUEL', duel.id, null, 'DUEL');
    }
    for (final _MockRematch r in _rematches.values) {
      if (r.status == 'WAITING' && r.requestedBy.contains(_user!.id)) {
        return _activityJson('PRIVATE_DUEL', r.sourceBattleId, null, 'REMATCH');
      }
    }
    return _activityJson('NONE', null, null, null);
  }

  Map<String, dynamic> _activityJson(
    String type,
    String? resourceId,
    String? battleId,
    String? kind,
  ) => <String, dynamic>{
    'type': type,
    'resourceId': resourceId,
    'battleId': battleId,
    'resourceKind': kind,
  };

  bool get _hasActivity => _activity()['type'] != 'NONE';

  // ----------------------------------------------------------- matchmaking

  Map<String, dynamic> _joinQueue(String code) {
    if (_hasActivity) {
      throw _error(409, 'ACTIVITY_CONFLICT', 'Another activity is open.');
    }
    if (!_canStartRanked) throw _limitError();
    final _MockQueue queue = _MockQueue(
      id: _id(),
      discipline: code,
      createdAt: _now,
      expiresAt: _now.add(const Duration(seconds: 90)),
    );
    _queue = queue;
    Timer(const Duration(seconds: 2), () {
      if (queue.status != 'SEARCHING') return;
      queue.ratingWindow = 200;
      queue.version++;
      _emit(
        RealtimeEventType.queueChanged,
        queue.id,
        queue.version,
        queue.toJson(),
      );
    });
    Timer(const Duration(milliseconds: 4500), () {
      if (queue.status != 'SEARCHING') return;
      final _MockBattle battle = _createBattle(code, 'RANKED');
      queue
        ..status = 'MATCHED'
        ..battleId = battle.id
        ..version += 1;
      _emit(
        RealtimeEventType.queueChanged,
        queue.id,
        queue.version,
        queue.toJson(),
      );
    });
    return queue.toJson();
  }

  _MockQueue _ownQueue(String id) {
    final _MockQueue? queue = _queue;
    if (queue == null || queue.id != id) {
      throw _error(404, 'QUEUE_ENTRY_NOT_FOUND', 'Queue entry not found.');
    }
    return queue;
  }

  Object? _cancelQueue(_MockQueue queue) {
    if (queue.status == 'MATCHED') {
      throw _error(409, 'MATCH_ALREADY_FOUND', 'A match was already found.');
    }
    queue
      ..status = 'CANCELLED'
      ..version += 1;
    return null;
  }

  // ----------------------------------------------------------------- duels

  Map<String, dynamic> _createDuel(String code) {
    if (_hasActivity) {
      throw _error(409, 'ACTIVITY_CONFLICT', 'Another activity is open.');
    }
    final _MockDuel duel = _MockDuel(
      id: _id(),
      code: _roomCode(),
      discipline: code,
      host: _MockPlayer(
        id: _user!.id,
        nickname: _user!.nickname,
        isPro: _isPro,
        rating: 0,
      ),
      expiresAt: _now.add(const Duration(minutes: 10)),
    );
    _duel = duel;
    Timer(const Duration(seconds: 6), () {
      if (duel.status != 'WAITING') return;
      final _MockBattle battle = _createBattle(code, 'PRIVATE');
      duel
        ..guest = battle.bot
        ..status = 'MATCHED'
        ..battleId = battle.id
        ..version += 1;
      _emit(
        RealtimeEventType.privateDuelChanged,
        duel.id,
        duel.version,
        duel.toJson(),
      );
    });
    return duel.toJson();
  }

  String _roomCode() {
    const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List<String>.generate(
      6,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }

  Map<String, dynamic> _joinDuel(String code) {
    if (_duel?.code == code) {
      throw _error(
        409,
        'SELF_JOIN_NOT_ALLOWED',
        'You cannot join your own room.',
      );
    }
    if (code == 'EXPIRE') {
      throw _error(410, 'DUEL_EXPIRED', 'The code has expired.');
    }
    if (code == 'NOROOM') {
      throw _error(404, 'DUEL_NOT_FOUND', 'No room with this code.');
    }
    if (_hasActivity) {
      throw _error(409, 'ACTIVITY_CONFLICT', 'Another activity is open.');
    }
    final _MockBattle battle = _createBattle('SAT_MATH', 'PRIVATE');
    final _MockDuel duel =
        _MockDuel(
            id: _id(),
            code: code,
            discipline: 'SAT_MATH',
            host: battle.bot,
            expiresAt: _now.add(const Duration(minutes: 8)),
          )
          ..guest = _MockPlayer(
            id: _user!.id,
            nickname: _user!.nickname,
            isPro: _isPro,
            rating: 0,
          )
          ..status = 'MATCHED'
          ..battleId = battle.id
          ..version = 2;
    return duel.toJson();
  }

  _MockDuel _ownDuel(String id) {
    final _MockDuel? duel = _duel;
    if (duel == null || duel.id != id) {
      throw _error(404, 'DUEL_NOT_FOUND', 'Room not found.');
    }
    return duel;
  }

  Object? _cancelDuel(_MockDuel duel) {
    if (duel.status == 'MATCHED') {
      throw _error(409, 'MATCH_ALREADY_FOUND', 'The match has started.');
    }
    duel
      ..status = 'CANCELLED'
      ..version += 1;
    return null;
  }

  // --------------------------------------------------------------- battles

  _MockBattle _createBattle(String code, String mode) {
    final int myRating = _rating[code]!;
    final int botRating = myRating + _random.nextInt(81) - 40;
    final _MockPlayer me = _MockPlayer(
      id: _user!.id,
      nickname: _user!.nickname,
      isPro: _isPro,
      rating: myRating,
    );
    final String botName = _botNames[_random.nextInt(_botNames.length)];
    final _MockPlayer bot = _MockPlayer(
      id: _botId(botName),
      nickname: botName,
      isPro: _random.nextBool(),
      rating: math.max(0, botRating),
    );
    final List<String> grid = MockContent.gridFor(
      math.min(me.rating, bot.rating),
    );
    final List<_MockRound> rounds = <_MockRound>[];
    final List<(String, String, String, String, List<String>, int, String)>
    bank = MockContent.bank(code);
    final Set<int> used = <int>{};
    for (int i = 0; i < 6; i++) {
      final String difficulty = i < 5 ? grid[i] : 'MEDIUM';
      int pick = -1;
      for (int j = 0; j < bank.length; j++) {
        if (!used.contains(j) && bank[j].$3 == difficulty) {
          pick = j;
          break;
        }
      }
      if (pick < 0) {
        pick = List<int>.generate(
          bank.length,
          (int j) => j,
        ).firstWhere((int j) => !used.contains(j));
      }
      used.add(pick);
      final (
        String topic,
        String topicName,
        String diff,
        String prompt,
        List<String> options,
        int correct,
        String explanation,
      ) = bank[pick];
      final List<String> optionIds = List<String>.generate(4, (_) => _id());
      rounds.add(
        _MockRound(
          id: _id(),
          number: i + 1,
          overtime: i == 5,
          questionId: _id(),
          topicCode: topic,
          topicName: topicName,
          difficulty: i == 5 ? 'MEDIUM' : diff,
          prompt: prompt,
          optionIds: optionIds,
          optionTexts: options,
          correctOptionId: optionIds[correct],
          explanation: explanation,
          limitSeconds: i == 5
              ? MockContent.limitSeconds(code, 'MEDIUM') ~/ 2
              : MockContent.limitSeconds(code, diff),
        ),
      );
    }
    final _MockBattle battle = _MockBattle(
      id: _id(),
      discipline: code,
      mode: mode,
      createdAt: _now,
      me: me,
      bot: bot,
      rounds: rounds,
      opponent: scenario.opponent,
      quotaCancel: mode == 'RANKED' && scenario.cancelNextRankedForQuota,
    );
    if (battle.quotaCancel) scenario.cancelNextRankedForQuota = false;
    battle.readyDeadline = _now.add(const Duration(seconds: 30));
    _battles[battle.id] = battle;
    _live = battle;
    battle.schedule(const Duration(milliseconds: 1500), () {
      battle.bot.ready = true;
      _changed(battle);
      _maybeStartCountdown(battle);
    });
    battle.schedule(const Duration(seconds: 30), () {
      if (battle.phase == 'WAITING_READY') _cancel(battle, 'READY_TIMEOUT');
    });
    return battle;
  }

  Object? _battleRoute(
    String method,
    String action,
    _MockBattle battle,
    Map<String, dynamic> data,
    Map<String, dynamic>? query,
  ) {
    switch ('$method $action') {
      case 'GET ':
        if (!_canOpen(battle)) throw _historyLocked();
        return _snapshot(battle);
      case 'POST readiness':
        if (battle.phase != 'WAITING_READY') {
          throw _error(409, 'INVALID_BATTLE_STATE', 'The ready check is over.');
        }
        if (battle.mode == 'RANKED' &&
            !_canStartRanked &&
            !battle.quotaCancel) {
          throw _limitError();
        }
        battle.me.ready = true;
        _changed(battle);
        _maybeStartCountdown(battle);
        return _snapshot(battle);
      case 'POST answers':
        return _answer(battle, data);
      case 'POST surrender':
        if (!battle.isTerminal) {
          if (battle.firstQuestionStarted) {
            _finish(battle, 'SURRENDER', winner: battle.bot.id);
          } else {
            _cancel(battle, 'SURRENDER');
          }
        }
        return _snapshot(battle);
      case 'GET result':
        if (!battle.isTerminal) {
          throw _error(
            409,
            'BATTLE_NOT_FINISHED',
            'The battle is still running.',
          );
        }
        if (!_canOpen(battle)) throw _historyLocked();
        return _result(battle);
      case 'GET review':
        if (!battle.isTerminal) {
          throw _error(
            409,
            'BATTLE_NOT_FINISHED',
            'The battle is still running.',
          );
        }
        if (!_canOpen(battle)) throw _historyLocked();
        final bool mistakesOnly = query?['mistakesOnly'] == true;
        if (mistakesOnly && !_isPro) {
          throw _error(
            403,
            'PRO_REQUIRED',
            'SkillBattles Pro is required for this feature.',
          );
        }
        return _review(battle, mistakesOnly: mistakesOnly);
      case 'GET rematch':
        final _MockRematch? rematch = _rematches[battle.id];
        if (rematch == null) {
          throw _error(404, 'REMATCH_NOT_FOUND', 'No rematch for this battle.');
        }
        return rematch.toJson();
      case 'POST rematch':
        return _requestRematch(battle);
      case 'DELETE rematch':
        final _MockRematch? rematch = _rematches[battle.id];
        if (rematch != null && rematch.status == 'MATCHED') {
          throw _error(409, 'MATCH_ALREADY_FOUND', 'The rematch has started.');
        }
        if (rematch != null && rematch.status == 'WAITING') {
          rematch
            ..status = 'CANCELLED'
            ..version += 1;
          _emit(
            RealtimeEventType.rematchChanged,
            battle.id,
            rematch.version,
            rematch.toJson(),
          );
        }
        return null;
    }
    if (method == 'POST' &&
        action.startsWith('rounds/') &&
        action.endsWith('/report')) {
      final String roundId = action.split('/')[1];
      final String key = '${battle.id}/$roundId';
      final Map<String, dynamic>? existing = _reports[key];
      if (existing != null) {
        if (existing['reason'] != data['reason'] ||
            existing['comment'] != data['comment']) {
          throw _error(
            409,
            'REPORT_ALREADY_EXISTS',
            'A different report exists.',
          );
        }
        return existing['response'];
      }
      final Map<String, dynamic> response = <String, dynamic>{
        'id': _id(),
        'battleId': battle.id,
        'roundId': roundId,
        'status': 'RECEIVED',
        'createdAt': _iso(_now),
      };
      _reports[key] = <String, dynamic>{...data, 'response': response};
      return response;
    }
    throw _error(404, 'NOT_FOUND', 'Unknown battle action.');
  }

  ApiDioError _historyLocked() => _error(
    403,
    'HISTORY_ACCESS_REQUIRED',
    'This match is outside your latest 10. Pro opens the full history.',
  );

  void _maybeStartCountdown(_MockBattle battle) {
    if (battle.phase != 'WAITING_READY' ||
        !battle.me.ready ||
        !battle.bot.ready) {
      return;
    }
    battle.phase = 'COUNTDOWN';
    battle.countdownEndsAt = _now.add(const Duration(seconds: 3));
    battle.readyDeadline = null;
    _changed(battle);
    battle.schedule(const Duration(seconds: 3), () {
      if (battle.quotaCancel) {
        _cancel(battle, 'QUOTA_EXHAUSTED');
        return;
      }
      if (battle.mode == 'RANKED') {
        // One attempt, consumed exactly when the first question opens.
        _rankedToday++;
        _emitAccount();
      }
      battle.firstQuestionStarted = true;
      _openRound(battle, 0);
    });
  }

  void _openRound(_MockBattle battle, int index) {
    final _MockRound round = battle.rounds[index];
    battle
      ..current = index
      ..phase = 'QUESTION'
      ..countdownEndsAt = null
      ..nextRoundStartsAt = null;
    round
      ..startedAt = _now
      ..deadline = _now.add(Duration(seconds: round.limitSeconds));
    battle.me.answered = false;
    battle.bot.answered = false;
    if (round.overtime) battle.overtimePlayed = true;
    _changed(battle);
    battle.schedule(Duration(seconds: round.limitSeconds), () {
      if (battle.phase == 'QUESTION' && battle.current == index) {
        _reveal(battle);
      }
    });
    _planBot(battle, round);
  }

  void _planBot(_MockBattle battle, _MockRound round) {
    final DevOpponent opponent = battle.opponent;
    if (opponent == DevOpponent.surrenders && round.number == 3) {
      battle.schedule(const Duration(seconds: 3), () {
        if (!battle.isTerminal) {
          _finish(battle, 'SURRENDER', winner: battle.me.id);
        }
      });
      return;
    }
    if (opponent == DevOpponent.disconnects && round.number == 2) {
      battle.schedule(const Duration(seconds: 2), () {
        battle.bot
          ..connected = false
          ..reconnectDeadline = _now.add(const Duration(seconds: 10));
        _changed(battle);
      });
      battle.schedule(const Duration(seconds: 12), () {
        if (!battle.isTerminal) {
          _finish(battle, 'DISCONNECT', winner: battle.me.id);
        }
      });
      return;
    }
    if (opponent == DevOpponent.timeout) return;
    final bool mirrors =
        opponent == DevOpponent.overtimeWin ||
        opponent == DevOpponent.overtimeDraw;
    if (mirrors && !round.overtime) return; // answers right after you
    final bool correct = switch (opponent) {
      DevOpponent.alwaysCorrect => true,
      DevOpponent.alwaysWrong => false,
      DevOpponent.overtimeWin => true,
      DevOpponent.overtimeDraw => false,
      _ => _random.nextDouble() < 0.6,
    };
    final int delayMs = switch (opponent) {
      DevOpponent.alwaysCorrect => 2500,
      DevOpponent.overtimeWin => 9000,
      _ => 3000 + _random.nextInt(7000),
    };
    battle.schedule(Duration(milliseconds: delayMs), () {
      _botAnswer(battle, round, correct: correct, elapsedMs: delayMs);
    });
  }

  void _botAnswer(
    _MockBattle battle,
    _MockRound round, {
    required bool correct,
    required int elapsedMs,
  }) {
    if (battle.phase != 'QUESTION' || battle.rounds[battle.current] != round) {
      return;
    }
    if (round.answers.containsKey(battle.bot.id)) return;
    final String option = correct
        ? round.correctOptionId
        : round.optionIds.firstWhere(
            (String id) => id != round.correctOptionId,
          );
    round.answers[battle.bot.id] = _MockAnswer(
      selectedOptionId: option,
      correct: correct,
      elapsedMs: elapsedMs,
    );
    battle.bot.answered = true;
    _changed(battle);
    _maybeReveal(battle);
  }

  Map<String, dynamic> _answer(_MockBattle battle, Map<String, dynamic> data) {
    final String submissionId = data['submissionId'] as String;
    final _MockRound round = battle.rounds.firstWhere(
      (_MockRound r) => r.id == data['roundId'],
      orElse: () => throw _error(400, 'VALIDATION_ERROR', 'Unknown round.'),
    );
    final _MockAnswer? existing = round.answers[_user!.id];
    if (existing != null) {
      if (existing.submissionId == submissionId &&
          existing.selectedOptionId == data['optionId']) {
        return _receipt(battle, round, existing);
      }
      throw existing.submissionId == submissionId
          ? _error(
              409,
              'IDEMPOTENCY_CONFLICT',
              'Different payload for this submission.',
            )
          : _error(
              409,
              'ANSWER_ALREADY_SUBMITTED',
              'An answer is already accepted.',
            );
    }
    if (battle.phase != 'QUESTION' ||
        battle.rounds[battle.current] != round ||
        !_now.isBefore(round.deadline!)) {
      throw _error(409, 'ROUND_CLOSED', 'The round is closed.');
    }
    final String optionId = data['optionId'] as String;
    if (!round.optionIds.contains(optionId)) {
      throw _error(400, 'INVALID_OPTION', 'Unknown option.');
    }
    final int elapsed = _now.difference(round.startedAt!).inMilliseconds;
    final _MockAnswer answer = _MockAnswer(
      selectedOptionId: optionId,
      correct: optionId == round.correctOptionId,
      elapsedMs: elapsed,
      submissionId: submissionId,
      acceptedAt: _now,
    );
    round.answers[_user!.id] = answer;
    battle.me.answered = true;
    _changed(battle);
    final DevOpponent opponent = battle.opponent;
    if ((opponent == DevOpponent.overtimeWin ||
            opponent == DevOpponent.overtimeDraw) &&
        !round.overtime) {
      battle.schedule(const Duration(milliseconds: 600), () {
        _botAnswer(battle, round, correct: answer.correct, elapsedMs: elapsed);
      });
    }
    _maybeReveal(battle);
    return _receipt(battle, round, answer);
  }

  Map<String, dynamic> _receipt(
    _MockBattle battle,
    _MockRound round,
    _MockAnswer a,
  ) => <String, dynamic>{
    'battleId': battle.id,
    'roundId': round.id,
    'submissionId': a.submissionId,
    'accepted': true,
    'acceptedAt': _iso(a.acceptedAt ?? _now),
  };

  void _maybeReveal(_MockBattle battle) {
    final _MockRound round = battle.rounds[battle.current];
    if (round.answers.containsKey(battle.me.id) &&
        round.answers.containsKey(battle.bot.id)) {
      // Both answered: the round closes early.
      battle.schedule(const Duration(milliseconds: 400), () {
        if (battle.phase == 'QUESTION' &&
            battle.rounds[battle.current] == round) {
          _reveal(battle);
        }
      });
    }
  }

  static const List<int> _streakBonus = <int>[0, 0, 100, 150, 200, 300];

  void _reveal(_MockBattle battle) {
    final _MockRound round = battle.rounds[battle.current];
    for (final _MockPlayer player in <_MockPlayer>[battle.me, battle.bot]) {
      final _MockAnswer answer = round.answers.putIfAbsent(
        player.id,
        () => _MockAnswer(
          selectedOptionId: null,
          correct: false,
          elapsedMs: null,
          timedOut: true,
        ),
      );
      if (round.overtime) continue;
      if (answer.correct) {
        player.streak++;
        final int limitMs = round.limitSeconds * 1000;
        final int remaining = (limitMs - (answer.elapsedMs ?? limitMs)).clamp(
          0,
          limitMs,
        );
        answer
          ..basePoints = MockContent.basePoints(round.difficulty)
          ..speedBonus = (200 * remaining / limitMs).floor()
          ..streakBonus = _streakBonus[math.min(player.streak, 5)];
        answer.points =
            answer.basePoints + answer.speedBonus + answer.streakBonus;
        player.correct++;
      } else {
        player.streak = 0;
      }
      player.score += answer.points;
    }
    if (round.overtime) {
      final _MockAnswer mine = round.answers[battle.me.id]!;
      final _MockAnswer theirs = round.answers[battle.bot.id]!;
      if (mine.correct) battle.me.correct++;
      if (theirs.correct) battle.bot.correct++;
      String? winner;
      if (mine.correct && !theirs.correct) winner = battle.me.id;
      if (!mine.correct && theirs.correct) winner = battle.bot.id;
      if (mine.correct &&
          theirs.correct &&
          mine.elapsedMs != theirs.elapsedMs) {
        winner = mine.elapsedMs! < theirs.elapsedMs!
            ? battle.me.id
            : battle.bot.id;
      }
      battle.overtimeWinner = winner;
      if (winner != null) {
        final _MockAnswer w = winner == battle.me.id ? mine : theirs;
        w
          ..tieBreakPoints = 1
          ..points = 1;
        (winner == battle.me.id ? battle.me : battle.bot).score += 1;
      }
    }
    round.revealed = true;
    battle
      ..phase = 'REVEAL'
      ..nextRoundStartsAt = _now.add(const Duration(seconds: 5));
    battle.me.answered = false;
    battle.bot.answered = false;
    _changed(battle);
    battle.schedule(const Duration(seconds: 5), () => _afterReveal(battle));
  }

  void _afterReveal(_MockBattle battle) {
    if (battle.isTerminal) return;
    final _MockRound round = battle.rounds[battle.current];
    if (round.overtime) {
      final String? winner = battle.overtimeWinner;
      _finish(
        battle,
        winner == null ? 'NORMAL' : 'OVERTIME_WIN',
        winner: winner,
      );
      return;
    }
    if (round.number < 5) {
      _openRound(battle, battle.current + 1);
      return;
    }
    if (battle.me.score == battle.bot.score) {
      _openRound(battle, 5);
      return;
    }
    _finish(
      battle,
      'NORMAL',
      winner: battle.me.score > battle.bot.score ? battle.me.id : battle.bot.id,
    );
  }

  void _finish(_MockBattle battle, String reason, {required String? winner}) {
    battle.cancelTimers();
    final _MockRound? open = battle.current >= 0
        ? battle.rounds[battle.current]
        : null;
    if (open != null && !open.revealed) open.interrupted = true;
    battle
      ..phase = 'FINISHED'
      ..status = 'FINISHED'
      ..reason = reason
      ..winner = winner
      ..finishedAt = _now
      ..nextRoundStartsAt = null;
    if (battle.mode == 'RANKED') {
      final int completed = _calibrated[battle.discipline]!;
      final int k = completed < 5 ? 64 : 32;
      final double expected =
          1 / (1 + math.pow(10, (battle.bot.rating - battle.me.rating) / 400));
      final double score = winner == null
          ? 0.5
          : (winner == battle.me.id ? 1 : 0);
      final double raw = k * (score - expected);
      final int delta = raw < 0 ? -((-raw) + 0.5).floor() : (raw + 0.5).floor();
      battle
        ..myK = k
        ..myDelta = delta
        ..myCalibrationLeft = math.max(0, 5 - completed - 1);
      _rating[battle.discipline] = math.max(0, battle.me.rating + delta);
      _calibrated[battle.discipline] = completed + 1;
      _peak[battle.discipline] = math.max(
        _peak[battle.discipline]!,
        _rating[battle.discipline]!,
      );
    }
    // The forfeiting loser earns no streak day.
    final bool iForfeited =
        (reason == 'SURRENDER' || reason == 'DISCONNECT') &&
        winner == battle.bot.id;
    if (!iForfeited) {
      _qualifiedDays.add(_date(_now.subtract(const Duration(hours: 5))));
    }
    _finished.add(battle);
    _changed(battle);
    _emitAccount();
  }

  void _cancel(_MockBattle battle, String reason) {
    battle.cancelTimers();
    battle
      ..phase = 'CANCELLED'
      ..status = 'CANCELLED'
      ..reason = reason
      ..finishedAt = _now;
    _changed(battle);
  }

  Map<String, dynamic> _requestRematch(_MockBattle battle) {
    if (battle.mode != 'PRIVATE' ||
        !battle.isTerminal ||
        battle.status != 'FINISHED') {
      throw _error(409, 'REMATCH_NOT_ALLOWED', 'A rematch is not possible.');
    }
    final _MockRematch? existing = _rematches[battle.id];
    if (existing != null) {
      if (existing.status == 'EXPIRED') {
        throw _error(410, 'REMATCH_EXPIRED', 'The rematch window has closed.');
      }
      if (existing.status != 'WAITING') {
        throw _error(409, 'REMATCH_NOT_ALLOWED', 'A rematch is not possible.');
      }
      if (!existing.requestedBy.contains(_user!.id)) {
        existing.requestedBy.add(_user!.id);
        _matchRematch(battle, existing);
      }
      return existing.toJson();
    }
    final _MockRematch rematch = _MockRematch(
      sourceBattleId: battle.id,
      requestedBy: <String>[_user!.id],
      expiresAt: _now.add(const Duration(seconds: 60)),
    );
    _rematches[battle.id] = rematch;
    Timer(const Duration(seconds: 3), () {
      if (rematch.status != 'WAITING') return;
      rematch.requestedBy.add(battle.bot.id);
      _matchRematch(battle, rematch);
    });
    Timer(const Duration(seconds: 60), () {
      if (rematch.status != 'WAITING') return;
      rematch
        ..status = 'EXPIRED'
        ..version += 1;
      _emit(
        RealtimeEventType.rematchChanged,
        battle.id,
        rematch.version,
        rematch.toJson(),
      );
    });
    return rematch.toJson();
  }

  void _matchRematch(_MockBattle source, _MockRematch rematch) {
    final _MockBattle next = _createBattle(source.discipline, 'PRIVATE');
    rematch
      ..status = 'MATCHED'
      ..battleId = next.id
      ..version += 1;
    _emit(
      RealtimeEventType.rematchChanged,
      source.id,
      rematch.version,
      rematch.toJson(),
    );
  }

  void _changed(_MockBattle battle) {
    battle.version++;
    _emit(
      RealtimeEventType.battleChanged,
      battle.id,
      battle.version,
      _snapshot(battle),
    );
  }

  // -------------------------------------------------------- battle views

  Map<String, dynamic> _playerJson(_MockBattle b, _MockPlayer p) =>
      <String, dynamic>{
        'id': p.id,
        'nickname': p.nickname,
        'isPro': p.isPro,
        'rating': p.rating,
        'rankCode': MockContent.rankCode(p.rating),
        'ready': p.ready,
        'connected': p.connected,
        'reconnectDeadline': p.reconnectDeadline == null
            ? null
            : _iso(p.reconnectDeadline!),
        'score': p.score,
        'correctCount': p.correct,
        'streak': p.streak,
        'answeredCurrentRound': p.answered,
      };

  Map<String, dynamic> _questionJson(_MockRound r) => <String, dynamic>{
    'id': r.questionId,
    'topicCode': r.topicCode,
    'topicName': r.topicName,
    'difficulty': r.difficulty,
    'prompt': r.prompt,
    'options': <Map<String, dynamic>>[
      for (int i = 0; i < 4; i++)
        <String, dynamic>{'id': r.optionIds[i], 'text': r.optionTexts[i]},
    ],
  };

  /// Free readers never get the correct option or the opponent's choice.
  Map<String, dynamic> _answerJson(
    _MockBattle b,
    String userId,
    _MockAnswer a,
  ) => <String, dynamic>{
    'userId': userId,
    'selectedOptionId': userId == _user!.id || _isPro
        ? a.selectedOptionId
        : null,
    'correct': a.correct,
    'elapsedMs': a.elapsedMs,
    'basePoints': a.basePoints,
    'speedBonus': a.speedBonus,
    'streakBonus': a.streakBonus,
    'tieBreakPoints': a.tieBreakPoints,
    'points': a.points,
    'timedOut': a.timedOut,
  };

  Map<String, dynamic> _access() => <String, dynamic>{
    'canViewCorrectAnswer': _isPro,
    'canViewExplanation': _isPro,
    'entitlementVersion': _entitlementVersion,
  };

  Map<String, dynamic> _snapshot(_MockBattle b) {
    final _MockRound? round =
        b.current >= 0 &&
            (b.phase == 'QUESTION' || b.phase == 'REVEAL' || b.isTerminal)
        ? b.rounds[b.current]
        : null;
    return <String, dynamic>{
      'id': b.id,
      'disciplineCode': b.discipline,
      'format': 'STANDARD',
      'mode': b.mode,
      'rulesVersion': '0.3',
      'seasonId': b.mode == 'RANKED' ? _seasonId : null,
      'phase': b.phase,
      'version': b.version,
      'serverTime': _iso(_now),
      'questionCount': 5,
      'overtimePlayed': b.overtimePlayed,
      'readyDeadline': b.readyDeadline == null ? null : _iso(b.readyDeadline!),
      'countdownEndsAt': b.countdownEndsAt == null
          ? null
          : _iso(b.countdownEndsAt!),
      'nextRoundStartsAt': b.nextRoundStartsAt == null
          ? null
          : _iso(b.nextRoundStartsAt!),
      'players': <Map<String, dynamic>>[
        _playerJson(b, b.me),
        _playerJson(b, b.bot),
      ],
      'round': round == null || round.startedAt == null
          ? null
          : <String, dynamic>{
              'id': round.id,
              'number': round.number,
              'isOvertimeRound': round.overtime,
              'startedAt': _iso(round.startedAt!),
              'deadline': _iso(round.deadline!),
              'limitSeconds': round.limitSeconds,
              'question': _questionJson(round),
              'mySelectedOptionId': round.answers[_user!.id]?.selectedOptionId,
              'reveal': !round.revealed
                  ? null
                  : <String, dynamic>{
                      'correctOptionId': _isPro ? round.correctOptionId : null,
                      'answers': <Map<String, dynamic>>[
                        for (final MapEntry<String, _MockAnswer> e
                            in round.answers.entries)
                          _answerJson(b, e.key, e.value),
                      ],
                      'answerAccess': _access(),
                    },
            },
      'result': b.isTerminal ? _result(b) : null,
      'entitlements': _entitlements(),
    };
  }

  Map<String, dynamic> _resultPlayer(_MockBattle b, _MockPlayer p) {
    final bool mine = p.id == _user!.id;
    final bool ranked = b.mode == 'RANKED' && b.status == 'FINISHED';
    final int delta = !ranked ? 0 : (mine ? b.myDelta : -b.myDelta);
    return <String, dynamic>{
      'id': p.id,
      'nickname': p.nickname,
      'isPro': p.isPro,
      'score': p.score,
      'correctCount': p.correct,
      'ratingBefore': p.rating,
      'ratingAfter': math.max(0, p.rating + delta),
      'ratingDelta': delta,
      'kFactor': ranked ? (mine ? b.myK : 32) : 0,
      'rankBefore': MockContent.rankCode(p.rating),
      'rankAfter': MockContent.rankCode(math.max(0, p.rating + delta)),
      'calibrationMatchesRemaining': mine ? b.myCalibrationLeft : 0,
    };
  }

  Map<String, dynamic> _result(_MockBattle b) => <String, dynamic>{
    'battleId': b.id,
    'disciplineCode': b.discipline,
    'format': 'STANDARD',
    'mode': b.mode,
    'seasonId': b.mode == 'RANKED' ? _seasonId : null,
    'rulesVersion': '0.3',
    'status': b.status,
    'reason': b.reason,
    'winnerUserId': b.winner,
    'myOutcome': b.outcomeFor(_user!.id),
    'finishedAt': _iso(b.finishedAt ?? _now),
    'overtimePlayed': b.overtimePlayed,
    'players': <Map<String, dynamic>>[
      _resultPlayer(b, b.me),
      _resultPlayer(b, b.bot),
    ],
  };

  Map<String, dynamic> _review(_MockBattle b, {required bool mistakesOnly}) {
    final List<_MockRound> rounds = b.rounds
        .where((_MockRound r) => r.startedAt != null)
        .where(
          (_MockRound r) =>
              !mistakesOnly || !(r.answers[_user!.id]?.correct ?? false),
        )
        .toList();
    return <String, dynamic>{
      'battleId': b.id,
      'disciplineCode': b.discipline,
      'mode': b.mode,
      'rulesVersion': '0.3',
      'mistakesOnly': mistakesOnly,
      'answerAccess': _access(),
      'rounds': <Map<String, dynamic>>[
        for (final _MockRound r in rounds)
          <String, dynamic>{
            'roundId': r.id,
            'number': r.number,
            'isOvertimeRound': r.overtime,
            'completed': r.revealed,
            'question': <String, dynamic>{
              ..._questionJson(r),
              'correctOptionId': _isPro ? r.correctOptionId : null,
              'explanation': _isPro ? r.explanation : null,
            },
            'answers': <Map<String, dynamic>>[
              for (final MapEntry<String, _MockAnswer> e in r.answers.entries)
                _answerJson(b, e.key, e.value),
            ],
          },
      ],
    };
  }

  // ------------------------------------------------------------- helpers

  void _emit(
    RealtimeEventType type,
    String resourceId,
    int version,
    Map<String, dynamic> data,
  ) {
    if (_events.isClosed || !_signedIn) return;
    _events.add(
      RealtimeEnvelope(
        eventId: _id(),
        type: type,
        resourceId: resourceId,
        version: version,
        occurredAt: _now,
        data: data,
      ),
    );
  }

  static String _iso(DateTime value) => value.toUtc().toIso8601String();

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  ApiDioError _error(
    int status,
    String code,
    String message, {
    Map<String, String> fieldErrors = const <String, String>{},
    DateTime? resetsAt,
  }) {
    final RequestOptions options = RequestOptions(path: 'mock');
    return ApiDioError(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<Object?>(
        requestOptions: options,
        statusCode: status,
        data: <String, dynamic>{
          'code': code,
          'message': message,
          'fieldErrors': <Map<String, String>>[
            for (final MapEntry<String, String> e in fieldErrors.entries)
              <String, String>{'field': e.key, 'message': e.value},
          ],
          'resetsAt': resetsAt == null ? null : _iso(resetsAt),
        },
      ),
    );
  }
}

/// A mock HTTP error shaped like a Dio bad response.
final class ApiDioError extends DioException {
  ApiDioError({
    required super.requestOptions,
    required super.type,
    required Response<Object?> super.response,
  });
}

final class _MockUser {
  const _MockUser({
    required this.id,
    required this.email,
    required this.nickname,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String nickname;
  final DateTime createdAt;

  _MockUser copyWith({String? nickname}) => _MockUser(
    id: id,
    email: email,
    nickname: nickname ?? this.nickname,
    createdAt: createdAt,
  );
}

final class _MockPlayer {
  _MockPlayer({
    required this.id,
    required this.nickname,
    required this.isPro,
    required this.rating,
  });

  final String id;
  final String nickname;
  final bool isPro;
  final int rating;
  bool ready = false;
  bool connected = true;
  DateTime? reconnectDeadline;
  int score = 0;
  int correct = 0;
  int streak = 0;
  bool answered = false;

  Map<String, dynamic> publicJson() => <String, dynamic>{
    'id': id,
    'nickname': nickname,
    'isPro': isPro,
  };
}

final class _MockAnswer {
  _MockAnswer({
    required this.selectedOptionId,
    required this.correct,
    required this.elapsedMs,
    this.timedOut = false,
    this.submissionId = '',
    this.acceptedAt,
  });

  final String? selectedOptionId;
  final bool correct;
  final int? elapsedMs;
  final bool timedOut;
  final String submissionId;
  final DateTime? acceptedAt;
  int basePoints = 0;
  int speedBonus = 0;
  int streakBonus = 0;
  int tieBreakPoints = 0;
  int points = 0;
}

final class _MockRound {
  _MockRound({
    required this.id,
    required this.number,
    required this.overtime,
    required this.questionId,
    required this.topicCode,
    required this.topicName,
    required this.difficulty,
    required this.prompt,
    required this.optionIds,
    required this.optionTexts,
    required this.correctOptionId,
    required this.explanation,
    required this.limitSeconds,
  });

  final String id;
  final int number;
  final bool overtime;
  final String questionId;
  final String topicCode;
  final String topicName;
  final String difficulty;
  final String prompt;
  final List<String> optionIds;
  final List<String> optionTexts;
  final String correctOptionId;
  final String explanation;
  final int limitSeconds;
  DateTime? startedAt;
  DateTime? deadline;
  bool revealed = false;
  bool interrupted = false;
  final Map<String, _MockAnswer> answers = <String, _MockAnswer>{};
}

final class _MockBattle {
  _MockBattle({
    required this.id,
    required this.discipline,
    required this.mode,
    required this.createdAt,
    required this.me,
    required this.bot,
    required this.rounds,
    required this.opponent,
    required this.quotaCancel,
  });

  final String id;
  final String discipline;
  final String mode;
  final DateTime createdAt;
  final _MockPlayer me;
  final _MockPlayer bot;
  final List<_MockRound> rounds;
  final DevOpponent opponent;
  final bool quotaCancel;
  String phase = 'WAITING_READY';
  String status = 'LIVE';
  String reason = 'NORMAL';
  String? winner;
  String? overtimeWinner;
  int version = 1;
  int current = -1;
  bool firstQuestionStarted = false;
  bool overtimePlayed = false;
  DateTime? readyDeadline;
  DateTime? countdownEndsAt;
  DateTime? nextRoundStartsAt;
  DateTime? finishedAt;
  int myDelta = 0;
  int myK = 0;
  int myCalibrationLeft = 0;
  final List<Timer> _timers = <Timer>[];

  bool get isTerminal => phase == 'FINISHED' || phase == 'CANCELLED';

  String outcomeFor(String userId) {
    if (status == 'CANCELLED') return 'CANCELLED';
    if (winner == null) return 'DRAW';
    return winner == userId ? 'WIN' : 'LOSS';
  }

  void schedule(Duration delay, void Function() action) {
    _timers.add(
      Timer(delay, () {
        if (!isTerminal) action();
      }),
    );
  }

  void cancelTimers() {
    for (final Timer timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }
}

final class _MockQueue {
  _MockQueue({
    required this.id,
    required this.discipline,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String discipline;
  final DateTime createdAt;
  final DateTime expiresAt;
  String status = 'SEARCHING';
  int ratingWindow = 100;
  String? battleId;
  int version = 1;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'disciplineCode': discipline,
    'format': 'STANDARD',
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'ratingWindow': ratingWindow,
    'battleId': battleId,
    'version': version,
    'error': null,
  };
}

final class _MockDuel {
  _MockDuel({
    required this.id,
    required this.code,
    required this.discipline,
    required this.host,
    required this.expiresAt,
  });

  final String id;
  final String code;
  final String discipline;
  final _MockPlayer host;
  final DateTime expiresAt;
  _MockPlayer? guest;
  String status = 'WAITING';
  String? battleId;
  int version = 1;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'code': code,
    'disciplineCode': discipline,
    'format': 'STANDARD',
    'status': status,
    'host': host.publicJson(),
    'guest': guest?.publicJson(),
    'expiresAt': expiresAt.toIso8601String(),
    'battleId': battleId,
    'version': version,
  };
}

final class _MockRematch {
  _MockRematch({
    required this.sourceBattleId,
    required this.requestedBy,
    required this.expiresAt,
  });

  final String sourceBattleId;
  final List<String> requestedBy;
  final DateTime expiresAt;
  String status = 'WAITING';
  String? battleId;
  int version = 1;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'sourceBattleId': sourceBattleId,
    'status': status,
    'requestedBy': List<String>.of(requestedBy),
    'expiresAt': expiresAt.toIso8601String(),
    'battleId': battleId,
    'version': version,
  };
}
