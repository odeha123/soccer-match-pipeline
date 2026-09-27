-- CHECK: every match appears exactly once in stg_matches.
-- Why: duplicates would double-count goals, wins and points downstream.
-- Returns the BAD rows. Zero rows = PASS.
--
-- New concept, HAVING: like WHERE, but it filters GROUPS after GROUP BY.
--   WHERE  -> filters rows   (before grouping)
--   HAVING -> filters groups (after grouping)

SELECT match_id,
       COUNT(*) AS copies
FROM 'data/staging/stg_matches.parquet'
GROUP BY match_id
HAVING COUNT(*) > 1
