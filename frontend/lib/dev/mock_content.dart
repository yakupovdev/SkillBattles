/// DEVELOPMENT ONLY. Fictional catalogue, ranks, plans and a tiny question
/// bank for the mock backend. Not real SAT content.
abstract final class MockContent {
  static const List<String> disciplines = <String>['SAT_MATH', 'SAT_RW'];

  static Map<String, dynamic> battleMode(String code) {
    final bool math = code == 'SAT_MATH';
    final int base = math ? 60 : 48;
    return <String, dynamic>{
      'disciplineCode': code,
      'displayName': math ? 'SAT Math' : 'SAT Reading & Writing',
      'description': math
          ? 'Practice quantitative reasoning skills.'
          : 'Practice reading and writing skills.',
      'active': true,
      'format': 'STANDARD',
      'questionType': 'SINGLE_CHOICE',
      'optionsCount': 4,
      'questionCount': 5,
      'baseQuestionSeconds': base,
      'difficultyTimings': <Map<String, dynamic>>[
        for (final (String d, double m, int p) in <(String, double, int)>[
          ('EASY', 0.75, 800),
          ('MEDIUM', 1, 1000),
          ('HARD', 1.5, 1200),
        ])
          <String, dynamic>{
            'difficulty': d,
            'limitSeconds': (base * m).round(),
            'basePoints': p,
          },
      ],
      'difficultySchedules': <Map<String, dynamic>>[
        for (final (int min, int? max, List<String> grid) in schedules)
          <String, dynamic>{
            'minRating': min,
            'maxRatingExclusive': max,
            'roundDifficulties': grid,
            'contentAvailable': true,
          },
      ],
      'overtimeSeconds': base ~/ 2,
      'readyTimeoutSeconds': 30,
      'countdownSeconds': 3,
      'revealSeconds': 5,
      'reconnectGraceSeconds': 30,
      'contentAvailable': true,
    };
  }

  static const List<(int, int?, List<String>)> schedules =
      <(int, int?, List<String>)>[
        (0, 1000, <String>['EASY', 'EASY', 'EASY', 'MEDIUM', 'MEDIUM']),
        (1000, 1900, <String>['EASY', 'EASY', 'MEDIUM', 'MEDIUM', 'HARD']),
        (1900, 2800, <String>['EASY', 'MEDIUM', 'MEDIUM', 'HARD', 'HARD']),
        (2800, null, <String>['MEDIUM', 'MEDIUM', 'HARD', 'HARD', 'HARD']),
      ];

  static List<String> gridFor(int lowerRating) {
    for (final (int min, int? max, List<String> grid) in schedules) {
      if (lowerRating >= min && (max == null || lowerRating < max)) return grid;
    }
    return schedules.last.$3;
  }

  static int limitSeconds(String code, String difficulty) {
    final int base = code == 'SAT_MATH' ? 60 : 48;
    return switch (difficulty) {
      'EASY' => (base * 0.75).round(),
      'HARD' => (base * 1.5).round(),
      _ => base,
    };
  }

  static int basePoints(String difficulty) => switch (difficulty) {
    'EASY' => 800,
    'HARD' => 1200,
    _ => 1000,
  };

  static const List<(String, String, int?, int?)> ranks =
      <(String, String, int?, int?)>[
        ('BRONZE', 'Bronze', 0, 1),
        ('BRONZE', 'Bronze', 300, 2),
        ('BRONZE', 'Bronze', 450, 3),
        ('IRON', 'Iron', 600, 1),
        ('IRON', 'Iron', 750, 2),
        ('IRON', 'Iron', 850, 3),
        ('SILVER', 'Silver', 1000, 1),
        ('SILVER', 'Silver', 1100, 2),
        ('SILVER', 'Silver', 1200, 3),
        ('GOLD', 'Gold', 1300, 1),
        ('GOLD', 'Gold', 1400, 2),
        ('GOLD', 'Gold', 1500, 3),
        ('PLATINUM', 'Platinum', 1600, 1),
        ('PLATINUM', 'Platinum', 1700, 2),
        ('PLATINUM', 'Platinum', 1800, 3),
        ('DIAMOND', 'Diamond', 1900, 1),
        ('DIAMOND', 'Diamond', 2000, 2),
        ('DIAMOND', 'Diamond', 2100, 3),
        ('EMERALD', 'Emerald', 2200, 1),
        ('EMERALD', 'Emerald', 2300, 2),
        ('EMERALD', 'Emerald', 2400, 3),
        ('BRILLIANT', 'Brilliant', 2500, 1),
        ('BRILLIANT', 'Brilliant', 2600, 2),
        ('BRILLIANT', 'Brilliant', 2700, 3),
        ('MASTER', 'Master', 2800, null),
        ('GRANDMASTER', 'Grandmaster', 3000, null),
        ('LEGEND', 'Legend', 3200, null),
      ];

  static const List<String> _roman = <String>['', 'I', 'II', 'III'];

  static List<Map<String, dynamic>> rankTiers() => <Map<String, dynamic>>[
    for (int i = 0; i < ranks.length; i++)
      <String, dynamic>{
        'code': _code(i),
        'displayName': _name(i),
        'leagueCode': ranks[i].$1,
        'floorRating': ranks[i].$3,
        'ceilingExclusive': i + 1 < ranks.length ? ranks[i + 1].$3 : null,
        'divisionNumber': ranks[i].$4,
      },
  ];

  static String _code(int i) => ranks[i].$4 == null
      ? ranks[i].$1
      : '${ranks[i].$1}_${_roman[ranks[i].$4!]}';

  static String _name(int i) => ranks[i].$4 == null
      ? ranks[i].$2
      : '${ranks[i].$2} ${_roman[ranks[i].$4!]}';

  static int _index(int rating) {
    int index = 0;
    for (int i = 0; i < ranks.length; i++) {
      if (rating >= ranks[i].$3!) index = i;
    }
    return index;
  }

  static String rankCode(int rating) => _code(_index(rating));

  static Map<String, dynamic> rankProgress(int rating) {
    final int i = _index(rating);
    final int floor = ranks[i].$3!;
    final int? ceiling = i + 1 < ranks.length ? ranks[i + 1].$3 : null;
    return <String, dynamic>{
      'rankCode': _code(i),
      'rankName': _name(i),
      'leagueCode': ranks[i].$1,
      'divisionRpCurrent': rating - floor,
      'divisionRpTarget': ceiling == null ? null : ceiling - floor,
      'floorRating': floor,
      'ceilingExclusive': ceiling,
    };
  }

  static List<Map<String, dynamic>> plans() => <Map<String, dynamic>>[
    <String, dynamic>{
      'code': 'FREE',
      'name': 'Free',
      'amountCents': 0,
      'currency': 'USD',
      'interval': 'NONE',
      'intervalCount': 0,
      'monthlyEquivalentCents': 0,
      'annualSavingsPercent': 0,
      'checkoutAvailable': false,
      'features': <String>[
        '5 ranked matches per day',
        'Latest 10 matches',
        'Basic statistics',
      ],
    },
    <String, dynamic>{
      'code': 'PRO_MONTHLY',
      'name': 'SkillBattles Pro Monthly',
      'amountCents': 799,
      'currency': 'USD',
      'interval': 'MONTH',
      'intervalCount': 1,
      'monthlyEquivalentCents': 799,
      'annualSavingsPercent': 0,
      'checkoutAvailable': true,
      'features': _proFeatures,
    },
    <String, dynamic>{
      'code': 'PRO_ANNUAL',
      'name': 'SkillBattles Pro Annual',
      'amountCents': 4799,
      'currency': 'USD',
      'interval': 'YEAR',
      'intervalCount': 1,
      'monthlyEquivalentCents': 400,
      'annualSavingsPercent': 50,
      'checkoutAvailable': true,
      'features': _proFeatures,
    },
  ];

  static const List<String> _proFeatures = <String>[
    'Unlimited ranked matches',
    'Full history and answer explanations',
    'Advanced analytics',
  ];

  /// (topicCode, topicName, difficulty, prompt, options, correctIndex,
  /// explanation).
  static const List<(String, String, String, String, List<String>, int, String)>
  math = <(String, String, String, String, List<String>, int, String)>[
    (
      'PERCENTAGES',
      'Percentages',
      'EASY',
      'What is 25% of 80?',
      <String>['20', '25', '30', '40'],
      0,
      '25% is one quarter; 80 ÷ 4 = 20.',
    ),
    (
      'PERCENTAGES',
      'Percentages',
      'EASY',
      'What is half of 50?',
      <String>['20', '25', '30', '35'],
      1,
      'Half of 50 is 25.',
    ),
    (
      'LINEAR',
      'Linear equations',
      'EASY',
      'If x + 7 = 12, what is x?',
      <String>['3', '4', '5', '19'],
      2,
      'Subtract 7 from both sides: x = 5.',
    ),
    (
      'RATIOS',
      'Ratios',
      'EASY',
      'A ratio of 2:3 has 10 parts in total. How many are in the larger share?',
      <String>['4', '5', '6', '8'],
      2,
      '10 ÷ 5 = 2 per part; 3 parts = 6.',
    ),
    (
      'RATIOS',
      'Ratios',
      'MEDIUM',
      'A recipe uses 2 cups for 4 servings. How many cups for 6 servings?',
      <String>['3', '4', '5', '6'],
      0,
      '2 × 6/4 = 3.',
    ),
    (
      'PERCENTAGES',
      'Percentages',
      'MEDIUM',
      'What is 15% of 200?',
      <String>['15', '20', '25', '30'],
      3,
      '0.15 × 200 = 30.',
    ),
    (
      'LINEAR',
      'Linear equations',
      'MEDIUM',
      'If 3x − 4 = 11, what is x?',
      <String>['3', '5', '7', '15'],
      1,
      'Add 4: 3x = 15, so x = 5.',
    ),
    (
      'GEOMETRY',
      'Geometry',
      'MEDIUM',
      'A rectangle is 6 by 4. What is its area?',
      <String>['10', '20', '24', '48'],
      2,
      'Area = 6 × 4 = 24.',
    ),
    (
      'PERCENTAGES',
      'Percentages',
      'HARD',
      'A price of 120 increases by 20%. What is the new price?',
      <String>['124', '132', '140', '144'],
      3,
      '120 × 1.2 = 144.',
    ),
    (
      'QUADRATIC',
      'Quadratics',
      'HARD',
      'What is the positive solution of x² − x − 6 = 0?',
      <String>['2', '3', '6', '1'],
      1,
      '(x − 3)(x + 2) = 0, so x = 3.',
    ),
    (
      'GEOMETRY',
      'Geometry',
      'HARD',
      'A right triangle has legs 6 and 8. How long is the hypotenuse?',
      <String>['10', '12', '14', '9'],
      0,
      '√(36 + 64) = √100 = 10.',
    ),
    (
      'LINEAR',
      'Linear equations',
      'HARD',
      'The line through (0, 2) and (2, 6) has what slope?',
      <String>['1', '2', '3', '4'],
      1,
      '(6 − 2) / (2 − 0) = 2.',
    ),
  ];

  static const List<(String, String, String, String, List<String>, int, String)>
  readingWriting = <(String, String, String, String, List<String>, int, String)>[
    (
      'GRAMMAR',
      'Standard English',
      'EASY',
      'Choose the correct word: "Each of the students ___ a notebook."',
      <String>['have', 'has', 'having', 'are having'],
      1,
      '"Each" is singular, so it takes "has".',
    ),
    (
      'VOCAB',
      'Words in context',
      'EASY',
      'Which word best means "brief"?',
      <String>['short', 'loud', 'heavy', 'bright'],
      0,
      '"Brief" means short in time or length.',
    ),
    (
      'PUNCT',
      'Punctuation',
      'EASY',
      'Which is punctuated correctly?',
      <String>[
        "Its raining.",
        "It's raining.",
        "Its' raining.",
        'It,s raining.',
      ],
      1,
      '"It\'s" is the contraction of "it is".',
    ),
    (
      'VOCAB',
      'Words in context',
      'EASY',
      'Which word is the opposite of "scarce"?',
      <String>['rare', 'plentiful', 'tiny', 'early'],
      1,
      'Scarce means in short supply; plentiful is its opposite.',
    ),
    (
      'GRAMMAR',
      'Standard English',
      'MEDIUM',
      'Choose the best form: "Neither the coach nor the players ___ ready."',
      <String>['was', 'is', 'were', 'be'],
      2,
      'With "neither…nor", the verb agrees with the nearer subject, "players".',
    ),
    (
      'TRANSITIONS',
      'Transitions',
      'MEDIUM',
      'The study was short. ___, its results were clear.',
      <String>['Therefore', 'Nevertheless', 'Similarly', 'For example'],
      1,
      'The sentences contrast, so "Nevertheless" fits.',
    ),
    (
      'VOCAB',
      'Words in context',
      'MEDIUM',
      'In "a tenuous argument", tenuous most nearly means:',
      <String>['weak', 'long', 'angry', 'famous'],
      0,
      'A tenuous argument is thin or weak.',
    ),
    (
      'PUNCT',
      'Punctuation',
      'MEDIUM',
      'Which uses a semicolon correctly?',
      <String>[
        'I ran; fast.',
        'I ran; I was late.',
        'I; ran late.',
        'I ran late;',
      ],
      1,
      'A semicolon joins two independent clauses.',
    ),
    (
      'TRANSITIONS',
      'Transitions',
      'HARD',
      'Prices rose sharply. ___, demand fell.',
      <String>['Consequently', 'Meanwhile', 'Likewise', 'Instead'],
      0,
      'The fall in demand results from the price rise.',
    ),
    (
      'GRAMMAR',
      'Standard English',
      'HARD',
      'Choose the correct pronoun: "The prize went to Maya and ___."',
      <String>['I', 'me', 'myself', 'mine'],
      1,
      'Object of the preposition "to" takes "me".',
    ),
    (
      'VOCAB',
      'Words in context',
      'HARD',
      'In "an ephemeral trend", ephemeral most nearly means:',
      <String>['lasting', 'brief', 'costly', 'popular'],
      1,
      'Ephemeral means short-lived.',
    ),
    (
      'PUNCT',
      'Punctuation',
      'HARD',
      'Which is correct?',
      <String>[
        "The team's coach",
        "The teams coach",
        "The teams' coach's",
        "The team coach's",
      ],
      0,
      'Singular possessive: team\'s.',
    ),
  ];

  static List<(String, String, String, String, List<String>, int, String)> bank(
    String code,
  ) => code == 'SAT_MATH' ? math : readingWriting;
}
