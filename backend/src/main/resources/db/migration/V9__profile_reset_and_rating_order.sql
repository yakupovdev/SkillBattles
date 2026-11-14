ALTER TABLE users ADD COLUMN birth_year integer, ADD COLUMN birth_month integer, ADD COLUMN birth_day integer;
ALTER TABLE ratings ADD COLUMN rating_reached_at timestamptz NOT NULL DEFAULT now();
CREATE INDEX ix_ratings_leaderboard ON ratings(discipline_code,season_id,rating DESC,rating_reached_at,user_id) WHERE deleted=false;
CREATE TABLE password_reset_tokens (
 id uuid PRIMARY KEY,created_at timestamp NOT NULL,updated_at timestamp NOT NULL,deleted boolean NOT NULL DEFAULT false,
 user_id uuid NOT NULL REFERENCES users(id),token_hash varchar(64) NOT NULL,expires_at timestamptz NOT NULL,consumed_at timestamptz
);
CREATE UNIQUE INDEX ux_password_reset_hash ON password_reset_tokens(token_hash) WHERE deleted=false;
CREATE INDEX ix_password_reset_expiry ON password_reset_tokens(expires_at);
