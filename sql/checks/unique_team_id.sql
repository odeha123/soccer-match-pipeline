-- CHECK (uniqueness): every team appears exactly once in stg_teams.
-- Why: stg_teams is joined to other tables. A duplicate team would make
-- those joins fan out and double every total downstream.
-- Returns the BAD rows. Zero rows = PASS.

SELECT team_id, COUNT(*) AS copies
FROM 'data/staging/stg_teams.parquet'
GROUP BY team_id
HAVING COUNT(*) > 1
