CREATE TABLE subscription_accounts (
 id uuid PRIMARY KEY, created_at timestamp NOT NULL, updated_at timestamp NOT NULL, deleted boolean NOT NULL DEFAULT false,
 user_id uuid NOT NULL REFERENCES users(id),customer_id varchar(255),subscription_id varchar(255),
 plan_code varchar(255) NOT NULL DEFAULT 'FREE',status varchar(255) NOT NULL DEFAULT 'NONE',
 current_period_start timestamptz,current_period_end timestamptz,cancel_at_period_end boolean NOT NULL DEFAULT false,
 paid boolean NOT NULL DEFAULT false,pro_active boolean NOT NULL DEFAULT false,version integer NOT NULL DEFAULT 1,
 checkouts jsonb NOT NULL DEFAULT '{}'
);
CREATE UNIQUE INDEX ux_subscriptions_user ON subscription_accounts(user_id) WHERE deleted=false;
CREATE UNIQUE INDEX ux_subscriptions_customer ON subscription_accounts(customer_id) WHERE customer_id IS NOT NULL;
CREATE UNIQUE INDEX ux_subscriptions_provider ON subscription_accounts(subscription_id) WHERE subscription_id IS NOT NULL;
INSERT INTO subscription_accounts(id,created_at,updated_at,user_id) SELECT gen_random_uuid(),timezone('UTC',now()),timezone('UTC',now()),id FROM users WHERE deleted=false;
CREATE TABLE stripe_event_receipts(account_id uuid NOT NULL REFERENCES subscription_accounts(id),event_id varchar(255) PRIMARY KEY);
CREATE INDEX ix_stripe_event_receipts_account ON stripe_event_receipts(account_id);
CREATE TABLE ranked_usage (
 id uuid PRIMARY KEY,created_at timestamp NOT NULL,updated_at timestamp NOT NULL,deleted boolean NOT NULL DEFAULT false,
 user_id uuid NOT NULL REFERENCES users(id),battle_id uuid NOT NULL REFERENCES battles(id),usage_date date NOT NULL,
 started_at timestamptz NOT NULL,refunded boolean NOT NULL DEFAULT false
);
CREATE UNIQUE INDEX ux_ranked_usage_battle_user ON ranked_usage(battle_id,user_id) WHERE deleted=false;
CREATE INDEX ix_ranked_usage_day ON ranked_usage(user_id,usage_date) WHERE deleted=false AND refunded=false;
CREATE TABLE qualifying_days (
 id uuid PRIMARY KEY,created_at timestamp NOT NULL,updated_at timestamp NOT NULL,deleted boolean NOT NULL DEFAULT false,
 user_id uuid NOT NULL REFERENCES users(id),activity_date date NOT NULL
);
CREATE UNIQUE INDEX ux_qualifying_days_user_date ON qualifying_days(user_id,activity_date) WHERE deleted=false;
ALTER TABLE battles ADD COLUMN finished_at timestamptz;
UPDATE battles SET finished_at=CASE jsonb_typeof(result->'finishedAt') WHEN 'number' THEN to_timestamp((result->>'finishedAt')::double precision) ELSE (result->>'finishedAt')::timestamptz END WHERE result IS NOT NULL;
CREATE INDEX ix_battles_first_terminal_finished ON battles(first_user_id,finished_at DESC,id DESC) WHERE deleted=false AND phase IN ('FINISHED','CANCELLED');
CREATE INDEX ix_battles_second_terminal_finished ON battles(second_user_id,finished_at DESC,id DESC) WHERE deleted=false AND phase IN ('FINISHED','CANCELLED');
