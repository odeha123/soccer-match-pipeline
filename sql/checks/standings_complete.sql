-- CHECK (completeness): the standings mart has all 20 teams for every matchday,
-- with no gaps in the positions.
-- Returns the BAD matchdays. Zero rows = PASS.

SELECT matchday,
       COUNT(*)        AS teams,
       MIN(position)   AS top_position,
       MAX(position)   AS bottom_position
FROM 'data/marts/mart_standings.parquet'
GROUP BY matchday
HAVING COUNT(*) != 20
    OR MIN(position) != 1
