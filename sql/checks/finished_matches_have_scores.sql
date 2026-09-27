-- CHECK: a FINISHED match must have both scores filled in.
-- Why: unplayed (TIMED) matches are allowed to have empty scores,
--      but a finished match with a missing score is broken data.
-- Returns the BAD rows. Zero rows = PASS.
--
-- New concept, IS NULL: NULL means "no value". You can't test it with = NULL;
-- you must write IS NULL (or IS NOT NULL).

SELECT match_id, home_team, away_team, home_goals, away_goals
FROM 'data/staging/stg_matches.parquet'
WHERE status = 'FINISHED'
  AND (home_goals IS NULL OR away_goals IS NULL)
