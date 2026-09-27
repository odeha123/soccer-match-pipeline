-- CHECK: the result code (H / D / A) must agree with the score.
-- Written by: Ody
-- Returns the BAD rows. Zero rows = PASS.
--
-- Example of a BAD row: result = 'H' but home_goals is NOT greater than away_goals.
--
-- TODO: write a query that returns finished matches where:
--   result = 'H' but the home team didn't score more, OR
--   result = 'A' but the away team didn't score more, OR
--   result = 'D' but the scores aren't equal.
-- Hint: use brackets to group each pair, e.g. (result = 'H' AND home_goals <= away_goals)

SELECT match_id, home_team, away_team, home_goals, away_goals, result
FROM 'data/staging/stg_matches.parquet'
WHERE status = 'FINISHED'
  AND (
        (result = 'H' AND home_goals <= away_goals)
     OR (result = 'A' AND away_goals <= home_goals)
     OR (result = 'D' AND home_goals != away_goals)
  )