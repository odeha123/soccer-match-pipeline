-- CHECK: goals can never be negative.
-- Written by: Ody
-- Returns the BAD rows. Zero rows = PASS.
--
-- TODO: write a query that returns any match where home_goals OR away_goals
--       is less than 0. Show match_id, home_team, away_team, home_goals, away_goals.

SELECT match_id, home_team, away_team, home_goals, away_goals
FROM 'data/staging/stg_matches.parquet'
WHERE away_goals < 0
    OR home_goals < 0