-- mart_team_form: each team's rolling form, match by match.
--
-- Grain: one row per team per finished match.
-- Source: int_team_matches
-- Dashboard question: "Who's in form right now, and who's slumping?"
--
-- Technique: WINDOW FUNCTIONS. Unlike GROUP BY, a window function calculates
-- across a set of related rows WITHOUT collapsing them. Every match row stays,
-- and gains columns computed from that team's surrounding matches.
--
--   PARTITION BY team          -> each team is its own window
--   ORDER BY kickoff_utc       -> in date order
--   ROWS BETWEEN 4 PRECEDING
--        AND CURRENT ROW       -> this match + the 4 before it = last 5 games

SELECT team_id,
       team,
       match_id,
       matchday,
       kickoff_utc,
       opponent,
       venue,
       goals_for,
       goals_against,
       outcome,
       points,

       -- 1, 2, 3... this team's nth match of the season
       ROW_NUMBER() OVER (PARTITION BY team ORDER BY kickoff_utc)            AS match_number,

       -- running total of points so far this season
       SUM(points) OVER (PARTITION BY team ORDER BY kickoff_utc
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)::INTEGER AS season_points,

       -- points from the last 5 matches (max 15)
       SUM(points) OVER (PARTITION BY team ORDER BY kickoff_utc
                         ROWS BETWEEN 4 PRECEDING AND CURRENT ROW)::INTEGER  AS points_last_5,

       -- form string, oldest -> newest, e.g. 'WWDLW'
       array_to_string(
           list(outcome) OVER (PARTITION BY team ORDER BY kickoff_utc
                               ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), '') AS form_last_5,

       -- TRUE on each team's most recent match (handy dashboard filter)
       ROW_NUMBER() OVER (PARTITION BY team ORDER BY kickoff_utc DESC) = 1   AS is_latest_match
FROM 'data/marts/int_team_matches.parquet'
ORDER BY team, kickoff_utc
