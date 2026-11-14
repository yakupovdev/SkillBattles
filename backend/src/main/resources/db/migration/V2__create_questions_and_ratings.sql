CREATE TABLE ratings (
    id uuid PRIMARY KEY,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted boolean NOT NULL DEFAULT false,
    user_id uuid NOT NULL REFERENCES users(id),
    subject varchar(16) NOT NULL CHECK (subject IN ('MATH', 'ENGLISH')),
    rating integer NOT NULL CHECK (rating >= 0)
);
CREATE UNIQUE INDEX ux_ratings_active_user_subject ON ratings(user_id, subject) WHERE deleted = false;

-- Upgrade users created by the authentication-only version, without resetting any future ratings.
INSERT INTO ratings (id, created_at, updated_at, deleted, user_id, subject, rating)
SELECT gen_random_uuid(), timezone('UTC', now()), timezone('UTC', now()), false, u.id, s.subject, 1000
FROM users u CROSS JOIN (VALUES ('MATH'), ('ENGLISH')) AS s(subject)
WHERE u.deleted = false;

CREATE TABLE questions (
    id uuid PRIMARY KEY,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted boolean NOT NULL DEFAULT false,
    external_key varchar(200) NOT NULL CHECK (btrim(external_key) <> ''),
    content_version integer NOT NULL CHECK (content_version > 0),
    subject varchar(16) NOT NULL CHECK (subject IN ('MATH', 'ENGLISH')),
    topic varchar(200) NOT NULL CHECK (btrim(topic) <> ''),
    difficulty varchar(16) NOT NULL CHECK (difficulty = 'MEDIUM'),
    prompt text NOT NULL CHECK (btrim(prompt) <> ''),
    options jsonb NOT NULL CHECK (jsonb_typeof(options) = 'array' AND jsonb_array_length(options) = 4),
    correct_option_id uuid NOT NULL,
    explanation text NOT NULL CHECK (btrim(explanation) <> ''),
    active boolean NOT NULL DEFAULT false
);
CREATE UNIQUE INDEX ux_questions_revision ON questions(external_key, content_version) WHERE deleted = false;
CREATE UNIQUE INDEX ux_questions_active_key ON questions(external_key) WHERE active = true AND deleted = false;
CREATE INDEX ix_questions_available ON questions(subject, difficulty) WHERE active = true AND deleted = false;
