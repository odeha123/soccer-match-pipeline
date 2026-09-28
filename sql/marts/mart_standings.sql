-- mart_standings: the league table after every matchday.
--
-- Grain: one row per team per matchday (20 teams x N matchdays).
-- Sources: int_team_matches, stg_teams
-- Dashboard question: "How has the table changed over the season?"
--
-- Built as a chain of CTEs, each one a small readable step:
--   grid        every team x every matchday (so a team that hasn't played a
--               matchday yet, e.g. a postponed game, still gets a row)
--   per_round   each team's result in each matchday
--   filled      grid LEFT JOIN results (missing = 0)
--   cumulative  running totals with window functions
--   final       position via RANK(), using Premier League tiebreakers:
--               points, then goal difference, then goals scored
--
-- Note: matches are counted in the matchday they were SCHEDULED for.

WITH matchdays AS (
    SELECT DISTINCT matchday
    FROM 'data/marts/int_team_matches.parquet'
),

teams AS (
    SELECT team_id, team_name AS team
    FROM 'data/staging/stg_teams.parquet'
),

grid AS (
    SELECT t.team_id, t.team, m.matchday
    FROM teams AS t
    CROSS JOIN matchdays AS m
),

per_round AS (
    SELECT team_id,
           matchday,
           COUNT(*)                                        AS played,
           SUM(CASE WHEN outcome = 'W' THEN 1 ELSE 0 END)  AS wins,
           SUM(CASE WHEN outcome = 'D' THEN 1 ELSE 0 END)  AS draws,
           SUM(CASE WHEN outcome = 'L' THEN 1 ELSE 0 END)  AS losses,
           SUM(goals_for)                                  AS goals_for,
           SUM(goals_against)                              AS goals_against,
           SUM(points)                                     AS points
    FROM 'data/marts/int_team_matches.parquet'
    GROUP BY team_id, matchday
),

filled AS (
    SELECT g.team_id,
           g.team,
           g.matchday,
           COALESCE(r.played, 0)         AS played,
           COALESCE(r.wins, 0)           AS wins,
           COALESCE(r.draws, 0)          AS draws,
           COALESCE(r.losses, 0)         AS losses,
           COALESCE(r.goals_for, 0)      AS goals_for,
           COALESCE(r.goals_against, 0)  AS goals_against,
           COALESCE(r.points, 0)         AS points
    FROM grid AS g
    LEFT JOIN per_round AS r
      ON g.team_id = r.team_id
     AND g.matchday = r.matchday
),

cumulative AS (
    SELECT team_id,
           team,
           matchday,
           (SUM(played)        OVER running)::INTEGER AS played,
           (SUM(wins)          OVER running)::INTEGER AS wins,
           (SUM(draws)         OVER running)::INTEGER AS draws,
           (SUM(losses)        OVER running)::INTEGER AS losses,
           (SUM(goals_for)     OVER running)::INTEGER AS goals_for,
           (SUM(goals_against) OVER running)::INTEGER AS goals_against,
           (SUM(points)        OVER running)::INTEGER AS points
    FROM filled
    WINDOW running AS (PARTITION BY team_id ORDER BY matchday
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
)

SELECT *,
       goals_for - goals_against AS goal_difference,
       RANK() OVER (PARTITION BY matchday
                    ORDER BY points DESC,
                             goals_for - goals_against DESC,
                             goals_for DESC) AS position,
       matchday = MAX(matchday) OVER ()      AS is_latest_matchday
FROM cumulative
ORDER BY matchday, position, team
