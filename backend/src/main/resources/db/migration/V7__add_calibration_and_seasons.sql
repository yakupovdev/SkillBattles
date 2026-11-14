ALTER TABLE ratings ADD COLUMN calibration_completed_matches integer NOT NULL DEFAULT 0 CHECK (calibration_completed_matches >= 0);
ALTER TABLE ratings ADD COLUMN season_id varchar(32);
ALTER TABLE ratings ADD COLUMN season_peak_rating integer NOT NULL DEFAULT 1000 CHECK (season_peak_rating >= 0);
ALTER TABLE ratings ADD COLUMN all_time_peak_rating integer NOT NULL DEFAULT 1000 CHECK (all_time_peak_rating >= 0);
-- Local development foundation rows only; new accounts are initialized from the injected Clock.
UPDATE ratings SET season_id =
 CASE WHEN extract(month FROM timezone('America/New_York',now())) < 3 THEN 'WINTER_'
      WHEN extract(month FROM timezone('America/New_York',now())) < 6 THEN 'SPRING_'
      WHEN extract(month FROM timezone('America/New_York',now())) < 9 THEN 'SUMMER_'
      WHEN extract(month FROM timezone('America/New_York',now())) < 12 THEN 'FALL_' ELSE 'WINTER_' END
 || (extract(year FROM timezone('America/New_York',now()))::integer - CASE WHEN extract(month FROM timezone('America/New_York',now())) < 3 THEN 1 ELSE 0 END)::text,
 season_peak_rating=rating, all_time_peak_rating=rating;
ALTER TABLE ratings ALTER COLUMN season_id SET NOT NULL;

CREATE TABLE season_archives (
 id uuid PRIMARY KEY, created_at timestamp NOT NULL, updated_at timestamp NOT NULL, deleted boolean NOT NULL DEFAULT false,
 user_id uuid NOT NULL REFERENCES users(id), discipline_code varchar(64) NOT NULL REFERENCES disciplines(code),
 season_id varchar(32) NOT NULL, season jsonb NOT NULL, season_starts_at timestamptz NOT NULL,
 peak_rating integer NOT NULL CHECK (peak_rating >= 0), peak_rank_code varchar(32) NOT NULL,
 final_rating integer NOT NULL CHECK (final_rating >= 0)
);
CREATE UNIQUE INDEX ux_season_archives_active_identity ON season_archives(user_id,discipline_code,season_id) WHERE deleted=false;
CREATE INDEX ix_season_archives_user_history ON season_archives(user_id,season_starts_at DESC,discipline_code) WHERE deleted=false;
CREATE INDEX ix_season_archives_user_discipline_history ON season_archives(user_id,discipline_code,season_starts_at DESC) WHERE deleted=false;
CREATE INDEX ix_battles_active_ranked_discipline ON battles(discipline_code,first_user_id,second_user_id)
 WHERE deleted=false AND mode='RANKED' AND phase NOT IN ('FINISHED','CANCELLED');
