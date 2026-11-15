ALTER TABLE users ADD COLUMN friend_code varchar(12);
ALTER TABLE users ADD CONSTRAINT ck_users_friend_code CHECK (friend_code IS NULL OR friend_code ~ '^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{12}$');
-- Global uniqueness also retains codes belonging to soft-deleted accounts.
CREATE UNIQUE INDEX ux_users_friend_code ON users(friend_code) WHERE friend_code IS NOT NULL;

CREATE TABLE friend_relations (
    id uuid PRIMARY KEY,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted boolean NOT NULL DEFAULT false,
    user_low_id uuid NOT NULL REFERENCES users(id),
    user_high_id uuid NOT NULL REFERENCES users(id),
    requester_id uuid NOT NULL REFERENCES users(id),
    recipient_id uuid NOT NULL REFERENCES users(id),
    status varchar(16) NOT NULL CHECK(status IN ('PENDING','ACCEPTED','DECLINED','CANCELLED','REMOVED')),
    accepted_at timestamp with time zone,
    version integer NOT NULL CHECK(version>=1),
    CONSTRAINT ck_friend_pair CHECK(user_low_id<user_high_id),
    CONSTRAINT ck_friend_direction CHECK ((requester_id=user_low_id AND recipient_id=user_high_id) OR (requester_id=user_high_id AND recipient_id=user_low_id)),
    CONSTRAINT ck_friend_acceptance CHECK ((status IN ('ACCEPTED','REMOVED'))=(accepted_at IS NOT NULL))
);
CREATE UNIQUE INDEX ux_friend_live_pair ON friend_relations(user_low_id,user_high_id)
    WHERE deleted=false AND status IN ('PENDING','ACCEPTED');
CREATE INDEX ix_friend_incoming ON friend_relations(recipient_id,created_at DESC,id) WHERE deleted=false AND status='PENDING';
CREATE INDEX ix_friend_outgoing ON friend_relations(requester_id,created_at DESC,id) WHERE deleted=false AND status='PENDING';
CREATE INDEX ix_friend_low ON friend_relations(user_low_id,accepted_at DESC,id) WHERE deleted=false AND status='ACCEPTED';
CREATE INDEX ix_friend_high ON friend_relations(user_high_id,accepted_at DESC,id) WHERE deleted=false AND status='ACCEPTED';
