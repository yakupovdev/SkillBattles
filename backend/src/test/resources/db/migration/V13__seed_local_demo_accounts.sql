-- Explicitly requested local demonstration accounts, without administrative roles.
-- Passwords are BCrypt cost 10; no raw password, Stripe key, fake customer or receipt.
-- Existing accounts/passwords/subscriptions are never overwritten.
CREATE TEMPORARY TABLE local_demo_seed (
    id uuid, email text, nickname text, password_hash text, pro boolean
) ON COMMIT DROP;
INSERT INTO local_demo_seed VALUES
('993d64b5-a58a-58e8-b403-b4e24a7b1967'::uuid,'admin@gmail.com','admin','$2a$10$MikYVabVQvaPck0VQ0KXteDzuWYleF64gXM8a6gJWNEgi.seBYIOS',false),
('769765c1-9c73-5b60-ada0-1b8e8ff9f297'::uuid,'adminpro@gmail.com','adminpro','$2a$10$wvLFOiNQBIzZWrqoIiUL0emdEE7oFGMuoZu7t1UvTAMUr2VYlEoEC',true);

DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM users u JOIN local_demo_seed s
        ON u.email_normalized=s.email OR u.nickname_normalized=s.nickname OR u.id=s.id
        WHERE NOT u.deleted AND (u.id<>s.id OR u.email_normalized<>s.email OR u.nickname_normalized<>s.nickname)
    ) THEN
        RAISE EXCEPTION 'Demo account email/nickname already belongs to another user; no account was changed';
    END IF;
END $$;

INSERT INTO users(id,created_at,updated_at,deleted,email_normalized,nickname,nickname_normalized,password_hash,birth_year,birth_month)
SELECT id,timezone('UTC',now()),timezone('UTC',now()),false,email,nickname,nickname,password_hash,2000,1
FROM local_demo_seed s WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id=s.id);

INSERT INTO ratings(id,created_at,updated_at,deleted,user_id,discipline_code,rating,
                    calibration_completed_matches,season_id,season_peak_rating,all_time_peak_rating,rating_reached_at)
SELECT gen_random_uuid(),timezone('UTC',now()),timezone('UTC',now()),false,u.id,d.code,1000,0,
       CASE WHEN extract(month FROM timezone('America/New_York',now())) < 3 THEN 'WINTER_'
            WHEN extract(month FROM timezone('America/New_York',now())) < 6 THEN 'SPRING_'
            WHEN extract(month FROM timezone('America/New_York',now())) < 9 THEN 'SUMMER_'
            WHEN extract(month FROM timezone('America/New_York',now())) < 12 THEN 'FALL_' ELSE 'WINTER_' END
       || (extract(year FROM timezone('America/New_York',now()))::integer
           - CASE WHEN extract(month FROM timezone('America/New_York',now())) < 3 THEN 1 ELSE 0 END)::text,
       1000,1000,now()
FROM users u JOIN local_demo_seed s ON s.id=u.id CROSS JOIN disciplines d
WHERE NOT u.deleted AND NOT d.deleted AND d.active
ON CONFLICT (user_id,discipline_code) WHERE deleted=false DO NOTHING;

-- Demo-only Pro access is a local grant, not a verified Stripe payment.
-- No existing subscription is upgraded, downgraded, reset, or rebound.
INSERT INTO subscription_accounts(id,created_at,updated_at,deleted,user_id,plan_code,status,
                                  current_period_start,current_period_end,paid,pro_active)
SELECT gen_random_uuid(),timezone('UTC',now()),timezone('UTC',now()),false,u.id,
       CASE WHEN s.pro THEN 'PRO_ANNUAL' ELSE 'FREE' END,
       CASE WHEN s.pro THEN 'ACTIVE' ELSE 'NONE' END,
       CASE WHEN s.pro THEN now() END,CASE WHEN s.pro THEN now()+interval '100 years' END,s.pro,s.pro
FROM users u JOIN local_demo_seed s ON s.id=u.id WHERE NOT u.deleted
ON CONFLICT (user_id) WHERE deleted=false DO NOTHING;
