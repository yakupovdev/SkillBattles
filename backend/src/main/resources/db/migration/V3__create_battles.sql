CREATE TABLE battles (
    id uuid PRIMARY KEY,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted boolean NOT NULL DEFAULT false,
    first_user_id uuid NOT NULL REFERENCES users(id),
    second_user_id uuid NOT NULL REFERENCES users(id),
    subject varchar(16) NOT NULL CHECK (subject IN ('MATH', 'ENGLISH')),
    mode varchar(16) NOT NULL CHECK (mode IN ('RANKED', 'PRIVATE')),
    phase varchar(16) NOT NULL CHECK (phase IN ('WAITING_READY', 'COUNTDOWN', 'QUESTION', 'REVEAL', 'FINISHED', 'CANCELLED')),
    version integer NOT NULL CHECK (version >= 1),
    ready_deadline timestamp with time zone,
    countdown_ends_at timestamp with time zone,
    next_round_starts_at timestamp with time zone,
    next_transition_at timestamp with time zone,
    settled_at timestamp with time zone,
    winner_user_id uuid REFERENCES users(id),
    state jsonb NOT NULL CHECK (jsonb_typeof(state) = 'object'),
    result jsonb,
    CHECK (first_user_id <> second_user_id),
    CHECK (winner_user_id IS NULL OR winner_user_id IN (first_user_id, second_user_id)),
    CHECK ((phase IN ('FINISHED', 'CANCELLED')) = (result IS NOT NULL)),
    CHECK (settled_at IS NULL OR phase IN ('FINISHED', 'CANCELLED'))
);
CREATE INDEX ix_battles_first_user ON battles(first_user_id, created_at DESC) WHERE deleted = false;
CREATE INDEX ix_battles_second_user ON battles(second_user_id, created_at DESC) WHERE deleted = false;
CREATE INDEX ix_battles_pending ON battles(next_transition_at) WHERE deleted = false AND phase NOT IN ('FINISHED', 'CANCELLED');
