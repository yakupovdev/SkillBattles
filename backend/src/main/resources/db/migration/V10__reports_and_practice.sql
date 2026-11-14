CREATE TABLE question_reports (
 id uuid PRIMARY KEY,created_at timestamp NOT NULL,updated_at timestamp NOT NULL,deleted boolean NOT NULL DEFAULT false,
 user_id uuid NOT NULL REFERENCES users(id),battle_id uuid NOT NULL REFERENCES battles(id),round_id uuid NOT NULL,reason varchar(32) NOT NULL,comment varchar(1000)
);
CREATE UNIQUE INDEX ux_question_report_owner_round ON question_reports(user_id,battle_id,round_id) WHERE deleted=false;
CREATE TABLE practice_sessions (
 id uuid PRIMARY KEY,created_at timestamp NOT NULL,updated_at timestamp NOT NULL,deleted boolean NOT NULL DEFAULT false,
 user_id uuid NOT NULL REFERENCES users(id),source_battle_id uuid NOT NULL REFERENCES battles(id),source_round_id uuid NOT NULL,discipline_code varchar(64) NOT NULL,
 expires_at timestamptz NOT NULL,question jsonb NOT NULL,selected_option_id uuid,submission_id uuid,answered_at timestamptz
);
CREATE INDEX ix_practice_owner ON practice_sessions(user_id,expires_at);
