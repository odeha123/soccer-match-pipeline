-- mart_home_away: how each team performs at HOME vs AWAY.
--
-- Grain: one row per team per venue (20 teams x 2 venues = 40 rows).
-- Source: int_team_matches
-- Dashboard question: "Which teams rely on home advantage?"
--
-- Technique: conditional aggregation. SUM(CASE WHEN ... THEN 1 ELSE 0 END)
-- counts only the rows that meet a condition, so wins/draws/losses
-- come out as separate columns from one GROUP BY.

SELECT team_id,
       team,
       venue,
       COUNT(*)                                          AS played,
       SUM(CASE WHEN outcome = 'W' THEN 1 ELSE 0 END)::INTEGER    AS wins,
       SUM(CASE WHEN outcome = 'D' THEN 1 ELSE 0 END)::INTEGER    AS draws,
       SUM(CASE WHEN outcome = 'L' THEN 1 ELSE 0 END)::INTEGER    AS losses,
       SUM(goals_for)::INTEGER                           AS goals_for,
       SUM(goals_against)::INTEGER                       AS goals_against,
       (SUM(goals_for) - SUM(goals_against))::INTEGER    AS goal_difference,
       SUM(points)::INTEGER                              AS points,
       ROUND(SUM(points) / COUNT(*), 2)                  AS points_per_game
FROM 'data/marts/int_team_matches.parquet'
GROUP BY team_id, team, venue
ORDER BY team, venue
