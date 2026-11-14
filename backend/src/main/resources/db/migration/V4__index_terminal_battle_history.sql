CREATE INDEX ix_battles_first_user_history ON battles(first_user_id, created_at DESC, id DESC)
    WHERE deleted = false AND phase IN ('FINISHED', 'CANCELLED');
CREATE INDEX ix_battles_second_user_history ON battles(second_user_id, created_at DESC, id DESC)
    WHERE deleted = false AND phase IN ('FINISHED', 'CANCELLED');
