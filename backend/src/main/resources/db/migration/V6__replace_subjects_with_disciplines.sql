-- This foundation intentionally has no v0.2 question/battle compatibility adapter.
-- Refuse an accidental migration of a shared populated bank/history; never delete it.
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM questions) OR EXISTS (SELECT 1 FROM battles) THEN
        RAISE EXCEPTION 'v0.3 foundation requires a separate database without v0.2 questions or battles';
    END IF;
END $$;

ALTER TABLE questions DROP CONSTRAINT questions_subject_check;
ALTER TABLE questions DROP CONSTRAINT questions_difficulty_check;
ALTER TABLE questions RENAME COLUMN subject TO discipline_code;
ALTER TABLE questions ALTER COLUMN discipline_code TYPE varchar(64);
ALTER TABLE questions RENAME COLUMN topic TO topic_name;
ALTER TABLE questions ADD COLUMN topic_code varchar(64) NOT NULL;
ALTER TABLE questions ADD CHECK (difficulty IN ('EASY','MEDIUM','HARD'));
ALTER TABLE questions ADD CHECK (topic_code ~ '^[A-Z][A-Z0-9_]{1,63}$');
ALTER TABLE questions ADD FOREIGN KEY (discipline_code) REFERENCES disciplines(code);

ALTER TABLE ratings DROP CONSTRAINT ratings_subject_check;
ALTER TABLE ratings RENAME COLUMN subject TO discipline_code;
ALTER TABLE ratings ALTER COLUMN discipline_code TYPE varchar(64);
UPDATE ratings SET discipline_code = CASE discipline_code WHEN 'MATH' THEN 'SAT_MATH' WHEN 'ENGLISH' THEN 'SAT_RW' END;
ALTER TABLE ratings ADD FOREIGN KEY (discipline_code) REFERENCES disciplines(code);
ALTER INDEX ux_ratings_active_user_subject RENAME TO ux_ratings_active_user_discipline;

ALTER TABLE battles DROP CONSTRAINT battles_subject_check;
ALTER TABLE battles RENAME COLUMN subject TO discipline_code;
ALTER TABLE battles ALTER COLUMN discipline_code TYPE varchar(64);
ALTER TABLE battles ADD FOREIGN KEY (discipline_code) REFERENCES disciplines(code);
ALTER TABLE battles ADD COLUMN format varchar(16) NOT NULL DEFAULT 'STANDARD' CHECK (format = 'STANDARD');
