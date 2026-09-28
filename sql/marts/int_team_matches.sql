-- int_team_matches: one row per TEAM per finished match.
-- ("int_" = intermediate: a building block that the marts use, not shown on the dashboard.)
--
-- Grain: one row per team per match, so every match appears TWICE:
--        once from the home team's point of view, once from the away team's.
--
-- Why? In stg_matches, Arsenal's games are split across two columns
-- (home_team and away_team). Answering "how is Arsenal doing?" means checking both.
-- Here every team's games live in ONE column (team), which makes every mart simpler.
--
-- New concept, UNION ALL: stacks two query results on top of each other.
-- Both halves must have the same columns in the same order.

-- Half 1: every match from the HOME team's point of view
SELECT match_id,
       matchday,
       kickoff_utc,
       home_team_id AS team_id,
       home_team    AS team,
       away_team    AS opponent,
       'Home'       AS venue,
       home_goals   AS goals_for,
       away_goals   AS goals_against,
       CASE result WHEN 'H' THEN 'W' WHEN 'D' THEN 'D' ELSE 'L' END AS outcome,
       CASE result WHEN 'H' THEN 3   WHEN 'D' THEN 1   ELSE 0   END AS points
FROM 'data/staging/stg_matches.parquet'
WHERE status = 'FINISHED'

UNION ALL

-- Half 2: the same matches from the AWAY team's point of view
SELECT match_id,
       matchday,
       kickoff_utc,
       away_team_id AS team_id,
       away_team    AS team,
       home_team    AS opponent,
       'Away'       AS venue,
       away_goals   AS goals_for,
       home_goals   AS goals_against,
       CASE result WHEN 'A' THEN 'W' WHEN 'D' THEN 'D' ELSE 'L' END AS outcome,
       CASE result WHEN 'A' THEN 3   WHEN 'D' THEN 1   ELSE 0   END AS points
FROM 'data/staging/stg_matches.parquet'
WHERE status = 'FINISHED'
