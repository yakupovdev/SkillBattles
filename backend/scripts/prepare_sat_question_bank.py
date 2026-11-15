"""Prepare a NEW SQL data migration from the supplied SAT Markdown documents.

Does not connect to a database. Existing/applied migrations must not be regenerated.
Use --output for a new version; the destination must not already exist.
Source text, source choices and explanations are preserved. Only the 23 explicitly
listed short-answer questions receive authored distractors, as agreed with the owner.
"""
import argparse
from collections import Counter
from fractions import Fraction
import hashlib
import json
from pathlib import Path
import re
import uuid


DISTRACTORS = {
    'ac472881': ['39', '104', '416'],
    'edc1b7b7': ['1', '6', '9'],
    '3008cfc3': ['11', '22', '66'],
    'd1b66ae6': ['2/3', '3', '2'],
    '00723d16': ['1/2', '3/4', '4'],
    'ff501705': ['3', '12', '18'],
    '40c09d66': ['6/7', '7', '13/6'],
    'b8f13a3a': ['10', '25', '40'],
    '46308566': ['8', '24', '32'],
    '983412ea': ['6', '18', '24'],
    '947a3cde': ['15', '45', '60'],
    '190be2fc': ['13', '26', '104'],
    '89ff6a0a': ['0.0462', '0.5', '65/62'],
    '002dba45': ['0.8235', '1/17', '17/3'],
    'e62cfe5f': ['1.3', '3.6', '5.2'],
    'e3cf671f': ['33', '66', '134'],
    '4b7bb316': ['405', '4200', '8405'],
    '46b2e169': ['0.13', '0.52', '50/13'],
    '81d0f1e6': ['189', '378', '1134'],
    'e9ed719f': ['0.03', '0.6', '3'],
    'fa80893a': ['8', '16', '34'],
    '3409707e': ['20', '40', '60'],
    '2b41a4c4': ['88', '440', '1760'],
}

TOPICS = {
    'Linear equations in one variable': 'ALGEBRA_LINEAR_ONE_VARIABLE',
    'Linear equations in two variables': 'ALGEBRA_LINEAR_TWO_VARIABLES',
    'Linear functions': 'ALGEBRA_LINEAR_FUNCTIONS',
    'Linear inequalities in one or two variables': 'ALGEBRA_LINEAR_INEQUALITIES',
    'Systems of two linear equations in two variables': 'ALGEBRA_LINEAR_SYSTEMS',
    'Equivalent expressions': 'ADVANCED_EQUIVALENT_EXPRESSIONS',
    'Nonlinear equations in one variable and systems of equations in two variables': 'ADVANCED_NONLINEAR_EQUATIONS',
    'Nonlinear functions': 'ADVANCED_NONLINEAR_FUNCTIONS',
    'Area and volume': 'GEOMETRY_AREA_VOLUME',
    'Circles': 'GEOMETRY_CIRCLES',
    'Lines, angles, and triangles': 'GEOMETRY_LINES_ANGLES_TRIANGLES',
    'Right triangles and trigonometry': 'GEOMETRY_RIGHT_TRIANGLES_TRIGONOMETRY',
    'Inference from sample statistics and margin of error': 'DATA_STATISTICAL_INFERENCE',
    'One-variable data: Distributions and measures of center and spread': 'DATA_ONE_VARIABLE',
    'Percentages': 'DATA_PERCENTAGES',
    'Probability and conditional probability': 'DATA_PROBABILITY',
    'Ratios, rates, proportional relationships, and units': 'DATA_RATIOS_RATES_UNITS',
    'Two-variable data: Models and scatterplots': 'DATA_TWO_VARIABLES',
    'Cross-Text Connections': 'CRAFT_CROSS_TEXT_CONNECTIONS',
    'Text Structure and Purpose': 'CRAFT_STRUCTURE_PURPOSE',
    'Words in Context': 'CRAFT_WORDS_IN_CONTEXT',
    'Rhetorical Synthesis': 'EXPRESSION_RHETORICAL_SYNTHESIS',
    'Transitions': 'EXPRESSION_TRANSITIONS',
    'Central Ideas and Details': 'INFORMATION_CENTRAL_IDEAS_DETAILS',
    'Command of Evidence': 'INFORMATION_COMMAND_OF_EVIDENCE',
    'Inferences': 'INFORMATION_INFERENCES',
    'Boundaries': 'CONVENTIONS_BOUNDARIES',
    'Form, Structure, and Sense': 'CONVENTIONS_FORM_STRUCTURE_SENSE',
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def option_id(external_key, key):
    # Same nameUUIDFromBytes (MD5, UUID v3) input as QuestionMapper.optionId.
    name = f'skillbattles:question:{len(external_key)}:{external_key}:1:{key}'
    return str(uuid.UUID(bytes=hashlib.md5(name.encode('utf-8')).digest(), version=3))


def parse(path, discipline):
    text = path.read_text(encoding='utf-8')
    parts = re.split(r'^### Question (\d+) \(ID: ([^)]+)\)\s*$', text, flags=re.M)
    require(len(parts) == 361, f'{path.name}: expected exactly 120 question headings')
    records = []
    for i in range(1, len(parts), 3):
        number, source_id, body = parts[i:i+3]
        # The separator and next Part heading belong to the document, not the rationale.
        body = re.split(r'\n---\s*\n', body, maxsplit=1)[0].strip()
        field = lambda name: re.search(r'^- \*\*' + name + r':\*\* (.+)$', body, re.M).group(1)
        require(field('Assessment') == 'SAT', f'{source_id}: unexpected assessment')
        require(field('Test') == ('Math' if discipline == 'SAT_MATH' else 'Reading and Writing'), f'{source_id}: unexpected test')
        prompt = re.search(r'^#### Question\s*\n(.*?)(?=^#### Choices|^\*\*Correct Answer:)', body, re.M | re.S).group(1).strip()
        answer = re.search(r'^\*\*Correct Answer:\*\* (.+)$', body, re.M).group(1).strip()
        answer = re.sub(r'^\*\*([^*]+)\*\*$', r'\1', answer)
        explanation = re.search(r'^#### Rationale\s*\n(.*)', body, re.M | re.S).group(1).strip()
        choices_match = re.search(r'^#### Choices\s*\n(.*?)^\*\*Correct Answer:', body, re.M | re.S)
        external_key = discipline + ':' + source_id
        authored = choices_match is None
        if choices_match:
            chunks = re.split(r'^- \*\*([ABCD])\.\*\*\s*', choices_match.group(1), flags=re.M)
            require(not chunks[0].strip(), f'{source_id}: unknown choice syntax')
            choices = [(chunks[j], chunks[j+1].strip()) for j in range(1, len(chunks), 2)]
            require([key for key, _ in choices] == list('ABCD') and answer in list('ABCD'), f'{source_id}: invalid A-D choices/answer')
            correct_key = answer
        else:
            require(source_id in DISTRACTORS, f'{source_id}: short answer needs reviewed distractors')
            wrong = DISTRACTORS[source_id]
            aliases = [Fraction(n) for n in re.findall(r'[+-]?(?:\d+/\d+|\d*\.\d+|\d+)', answer)]
            require(aliases and len({Fraction(n) for n in wrong}) == 3, f'{source_id}: invalid numeric choices')
            require(all(abs(Fraction(n)-correct) > Fraction(1, 1000) for n in wrong for correct in aliases), f'{source_id}: distractor matches an accepted answer/rounding')
            correct_index = int(source_id, 16) % 4
            values = wrong.copy()
            values.insert(correct_index, answer)
            choices = list(zip('ABCD', values))
            correct_key = 'ABCD'[correct_index]
        topic_code = TOPICS[field('Skill')]
        topic_name = field('Domain') + ' / ' + field('Skill')
        require(prompt and explanation and len(topic_name) <= 200, f'{source_id}: empty or oversized content')
        options = [dict(id=option_id(external_key, key), key=key, text=value) for key, value in choices]
        records.append(dict(
            id=str(uuid.uuid5(uuid.NAMESPACE_URL, 'skillbattles:seed:' + external_key + ':1')),
            external_key=external_key, discipline_code=discipline, topic_code=topic_code, topic_name=topic_name,
            difficulty=field('Difficulty'), prompt=prompt, options=options,
            correct_option_id=option_id(external_key, correct_key), explanation=explanation,
            source_id=source_id, source_number=int(number), authored_distractors=authored,
        ))
    require(Counter(r['difficulty'] for r in records) == {'EASY': 40, 'MEDIUM': 40, 'HARD': 40}, f'{path.name}: incorrect difficulty counts')
    return records


def migration(records, hashes):
    payload = json.dumps(records, ensure_ascii=False, indent=2)
    require('$sat_question_bank$' not in payload and '${' not in payload, 'Unexpected SQL delimiter or Flyway placeholder in source')
    header = '\n'.join([
        '-- Full supplied SAT bank: 240 questions, 120 per discipline, 40 per difficulty.',
        '-- Original prompts, explanations and 217 original choice sets are unchanged.',
        '-- The owner authorized A-D conversion for 23 numeric-response Math questions.',
        '-- authored_distractors=true identifies their three added wrong choices.',
        *['-- Source SHA-256 ' + name + ': ' + digest for name, digest in hashes.items()],
        '-- This migration only appends questions and merges catalogue topics; it never deletes rows.',
    ])
    return header + '''
CREATE TEMPORARY TABLE sat_question_seed ON COMMIT DROP AS
SELECT * FROM jsonb_to_recordset($sat_question_bank$
''' + payload + '''
$sat_question_bank$::jsonb) AS q(
    id uuid, external_key text, discipline_code text, topic_code text, topic_name text,
    difficulty text, prompt text, options jsonb, correct_option_id uuid, explanation text,
    source_id text, source_number integer, authored_distractors boolean
);

-- Abort atomically on a collision instead of changing an existing question/revision.
DO $$ BEGIN
    IF (SELECT count(*) FROM sat_question_seed) <> 240
       OR (SELECT count(DISTINCT external_key) FROM sat_question_seed) <> 240 THEN
        RAISE EXCEPTION 'SAT seed must contain 240 distinct questions';
    END IF;
    IF EXISTS (
        SELECT 1 FROM questions q JOIN sat_question_seed s ON q.external_key=s.external_key
        WHERE NOT q.deleted AND (
            q.content_version<>1 OR q.discipline_code<>s.discipline_code OR q.topic_code<>s.topic_code
            OR q.topic_name<>s.topic_name OR q.difficulty<>s.difficulty OR q.prompt<>s.prompt
            OR q.options<>s.options OR q.correct_option_id<>s.correct_option_id OR q.explanation<>s.explanation
        )
    ) THEN
        RAISE EXCEPTION 'SAT seed conflicts with existing content; no questions were replaced';
    END IF;
    IF EXISTS (
        SELECT 1 FROM disciplines d CROSS JOIN LATERAL jsonb_array_elements(d.topics) t
        JOIN sat_question_seed s ON s.discipline_code=d.code AND s.topic_code=t->>'topicCode'
        WHERE t->>'topicName' IS DISTINCT FROM s.topic_name
    ) THEN
        RAISE EXCEPTION 'SAT seed conflicts with existing topic metadata; no topics were replaced';
    END IF;
END $$;

INSERT INTO questions (
    id,created_at,updated_at,deleted,external_key,content_version,discipline_code,
    topic_code,topic_name,difficulty,prompt,options,correct_option_id,explanation,active
)
SELECT s.id,timezone('UTC',now()),timezone('UTC',now()),false,s.external_key,1,s.discipline_code,
       s.topic_code,s.topic_name,s.difficulty,s.prompt,s.options,s.correct_option_id,s.explanation,true
FROM sat_question_seed s
WHERE NOT EXISTS (SELECT 1 FROM questions q WHERE q.external_key=s.external_key AND NOT q.deleted);

-- Preserve pre-existing topics, names and gameplay configuration.
UPDATE disciplines d SET topics=(
    SELECT jsonb_agg(t.topic ORDER BY t.topic->>'topicCode')
    FROM (
        SELECT topic FROM jsonb_array_elements(d.topics) topic
        UNION
        SELECT DISTINCT jsonb_build_object('topicCode',s.topic_code,'topicName',s.topic_name)
        FROM sat_question_seed s WHERE s.discipline_code=d.code
    ) t
), updated_at=timezone('UTC',now())
WHERE d.code IN ('SAT_MATH','SAT_RW');
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--math', type=Path, required=True)
    parser.add_argument('--rw', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    records = parse(args.math, 'SAT_MATH') + parse(args.rw, 'SAT_RW')
    require(len({r['source_id'] for r in records}) == 240, 'Duplicate source ID')
    require({r['source_id'] for r in records if r['authored_distractors']} == set(DISTRACTORS), 'Short-answer set differs from the approved set')
    hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in (args.math, args.rw)}
    with args.output.open('x', encoding='utf-8', newline='\n') as output:
        output.write(migration(records, hashes))
    print('Prepared 240 questions: 217 unchanged choice sets, 23 reviewed A-D conversions. No database changed.')


if __name__ == '__main__':
    main()
