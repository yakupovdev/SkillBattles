# SAT question bank and local accounts

The agreed migration chain remains **V1–V13**, with no separate baseline.
Existing V1–V11 remain unchanged so deployed databases retain valid history and
checksums. V12/V13 append content/accounts without changing the existing schema,
gameplay rules, constraints, indexes, foreign keys or catalogue settings.

`V12` loads all **240** supplied questions: 120 SAT Math and 120 SAT Reading &
Writing. Each discipline has 40 EASY, 40 MEDIUM and 40 HARD questions. All 240
source IDs are unique. External keys are `SAT_MATH:<source ID>` / `SAT_RW:<source ID>`.

The exact source Markdown files are retained under `src/test/resources/question-bank/`:

| Source | SHA-256 |
| --- | --- |
| SAT_Questions_Math.md | `cb779fb46ce96a132821f573fb044397fc61e5f91641b2b37d2203fd1372407d` |
| SAT_Questions_RW.md | `9102ba7e7c8a663974fac00ebb5b795da620966321b4a2e02ac75cb71d0967f8` |

Prompts, full rationales, difficulty and all 217 original A–D choice sets are
preserved. Domain and skill are retained together in `topicName`; stable topic
codes support existing analytics. Only line endings and surrounding section
whitespace are normalized. Tables, graph descriptions and LaTeX stay in the text.
Original answers/rationales are not silently corrected or recomputed.

## Authorized numeric-response conversions

The owner authorized converting the 23 Math numeric-response questions to the
existing four-choice format. Their correct answer text (including supplied
equivalent fractions/roundings) and rationale are unchanged. Three wrong numeric
choices were authored for each; no generated choice equals any accepted answer
or its stated rounding. These entries carry `authored_distractors=true` in the
migration payload. This is provenance metadata, not a new API field.

| Source ID | Difficulty | Correct key | Added wrong choices |
| --- | --- | --- | --- |
| `ac472881` | HARD | B | A: 39, C: 104, D: 416 |
| `edc1b7b7` | HARD | D | A: 1, B: 6, C: 9 |
| `3008cfc3` | HARD | D | A: 11, B: 22, C: 66 |
| `d1b66ae6` | HARD | C | A: 2/3, B: 3, D: 2 |
| `00723d16` | HARD | C | A: 1/2, B: 3/4, D: 4 |
| `ff501705` | HARD | B | A: 3, C: 12, D: 18 |
| `40c09d66` | HARD | C | A: 6/7, B: 7, D: 13/6 |
| `b8f13a3a` | HARD | C | A: 10, B: 25, D: 40 |
| `46308566` | HARD | C | A: 8, B: 24, D: 32 |
| `983412ea` | HARD | C | A: 6, B: 18, D: 24 |
| `947a3cde` | HARD | C | A: 15, B: 45, D: 60 |
| `190be2fc` | HARD | A | B: 13, C: 26, D: 104 |
| `89ff6a0a` | HARD | C | A: 0.0462, B: 0.5, D: 65/62 |
| `002dba45` | MEDIUM | B | A: 0.8235, C: 1/17, D: 17/3 |
| `e62cfe5f` | MEDIUM | D | A: 1.3, B: 3.6, C: 5.2 |
| `e3cf671f` | MEDIUM | D | A: 33, B: 66, C: 134 |
| `4b7bb316` | MEDIUM | C | A: 405, B: 4200, D: 8405 |
| `46b2e169` | MEDIUM | B | A: 0.13, C: 0.52, D: 50/13 |
| `81d0f1e6` | MEDIUM | C | A: 189, B: 378, D: 1134 |
| `e9ed719f` | MEDIUM | D | A: 0.03, B: 0.6, C: 3 |
| `fa80893a` | EASY | C | A: 8, B: 16, D: 34 |
| `3409707e` | EASY | C | A: 20, B: 40, D: 60 |
| `2b41a4c4` | EASY | A | B: 88, C: 440, D: 1760 |

## Local demonstration accounts

`V13` adds the explicitly requested `admin` / `admin@gmail.com` (Free) and
`adminpro` / `adminpro@gmail.com` (Pro), with password `qwerty12`. Independent
BCrypt cost-10 hashes are stored; SQL contains no plaintext password. Both get
initial 1000 ratings and zero calibration matches for active disciplines. The
year/month 2000/01 is a demo adult date, not a claim about a real person.

There are no administrative roles. Pro is an explicit local demo grant with a
100-year period, not a real payment: no Stripe customer, subscription ID or event
receipt is fabricated. Stripe verification and the other users’ entitlements
remain unchanged. These publicly known demonstration credentials are for local
test data; deployment data/account policy must be handled separately.

## Preservation and checks

The seed migrations append rows and never delete existing questions/accounts.
A conflicting question revision, topic label, email or nickname aborts the
migration transaction rather than replacing existing content or credentials.
Existing passwords/subscriptions/ratings are not reset on repeated startup.

`SeedMigrationSafetyPostgresTest` verifies the complete V1–V13 chain, unchanged
legacy history/data, successful upgrade and rollback on seed collisions.
`SeedQuestionBankPostgresTest` independently parses every source question and
compares prompt, rationale, difficulty, topic, original choices and correct
answer against PostgreSQL. It also checks Free/Pro login, content availability
for every matchmaking grid and idempotent repeated migration.

`scripts/prepare_sat_question_bank.py` can prepare a **new** migration from the
same document format. It refuses an existing output file: do not regenerate
an applied migration. It performs no database writes.
