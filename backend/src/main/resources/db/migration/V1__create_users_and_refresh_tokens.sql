CREATE TABLE users (
    id uuid PRIMARY KEY,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted boolean NOT NULL DEFAULT false,
    email_normalized varchar(254) NOT NULL,
    nickname varchar(24) NOT NULL,
    nickname_normalized varchar(24) NOT NULL,
    password_hash varchar(100) NOT NULL
);

CREATE UNIQUE INDEX ux_users_active_email ON users (email_normalized) WHERE deleted = false;
CREATE UNIQUE INDEX ux_users_active_nickname ON users (nickname_normalized) WHERE deleted = false;

CREATE TABLE refresh_tokens (
    id uuid PRIMARY KEY,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted boolean NOT NULL DEFAULT false,
    user_id uuid NOT NULL REFERENCES users (id),
    token_hash varchar(64) NOT NULL UNIQUE,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone
);

CREATE INDEX ix_refresh_tokens_user_id ON refresh_tokens (user_id);
