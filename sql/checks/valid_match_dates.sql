-- CHECK (validity): match dates and matchdays must make sense.
-- A bad row is one where:
--   * a match is FINISHED but its kickoff is in the future, or
--   * the matchday is outside 1-38 (a Premier League season has 38 rounds), or
--   * the kickoff date is missing.
-- Returns the BAD rows. Zero rows = PASS.

SELECT match_id, matchday, kickoff_utc, status, home_team, away_team
FROM 'data/staging/stg_matches.parquet'
WHERE kickoff_utc IS NULL
   OR matchday NOT BETWEEN 1 AND 38
   OR (status = 'FINISHED' AND kickoff_utc > (now() AT TIME ZONE 'UTC'))
