-- stg_teams: one clean row per Premier League team.
--
-- Grain: one row per team_id.
-- Source: every raw teams file in data/raw/teams/ (one file per ingest run).
--
-- Same pattern as stg_matches: flatten -> rename/type -> deduplicate.
-- Deduplication keeps the MOST RECENT pull of each team, so joining to this
-- table can never fan out (one row per team, guaranteed).

WITH raw AS (
    SELECT _pulled_at,
           unnest(payload.teams) AS t
    FROM read_json('data/raw/teams/*.json')
),

renamed AS (
    SELECT t.id::INTEGER        AS team_id,
           t.shortName          AS team_name,
           t.name               AS team_full_name,
           t.tla                AS team_code,
           t.venue              AS stadium,
           t.founded::INTEGER   AS founded,
           t.crest              AS crest_url,
           _pulled_at           AS pulled_at
    FROM raw
)

SELECT *
FROM renamed
QUALIFY ROW_NUMBER() OVER (PARTITION BY team_id ORDER BY pulled_at DESC) = 1
ORDER BY team_name
