-- CHECK (reconciliation): our calculated league table must match the
-- official table published by the API.
--
-- We build standings ourselves from match results. The API also publishes
-- the official table. If they disagree on any team's games played, points
-- or goal difference, something is wrong in our logic (or the source).
-- This is how analysts prove a derived number can be trusted: tie it back
-- to an independent source.
--
-- Returns the teams that DON'T match. Zero rows = PASS.

WITH latest_pull AS (
    SELECT payload
    FROM read_json('data/raw/standings/*.json')
    ORDER BY _pulled_at DESC
    LIMIT 1
),

official AS (
    SELECT r.team.id::INTEGER       AS team_id,
           r.team.shortName         AS team,
           r.playedGames::INTEGER   AS official_played,
           r.points::INTEGER        AS official_points,
           r.goalDifference::INTEGER AS official_gd
    FROM (SELECT unnest(payload.standings[1]."table") AS r FROM latest_pull)
),

ours AS (
    SELECT team_id, played, points, goal_difference
    FROM 'data/marts/mart_standings.parquet'
    WHERE is_latest_matchday
)

SELECT o.team,
       o.official_played, u.played          AS our_played,
       o.official_points, u.points          AS our_points,
       o.official_gd,     u.goal_difference AS our_gd
FROM official AS o
LEFT JOIN ours AS u
  ON o.team_id = u.team_id
WHERE u.team_id IS NULL
   OR o.official_played != u.played
   OR o.official_points != u.points
   OR o.official_gd     != u.goal_difference
