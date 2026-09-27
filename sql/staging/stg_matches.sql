-- stg_matches: one clean row per Premier League match.
--
-- Grain: one row per match_id.
-- Source: every raw matches file in data/raw/matches/ (one file per ingest run).
--
-- What this model does:
--   1. FLATTEN      nested JSON -> one row per match
--   2. RENAME/TYPE  API names (utcDate) -> our names (kickoff_utc), with proper types
--   3. DERIVE       add useful columns the API doesn't give directly (result, total_goals)
--   4. DEDUPLICATE  every ingest run re-downloads all 380 matches, so the same match
--                   appears once per run. Keep only the most recent version of each.

WITH raw AS (
    -- Step 1: open the "envelope". One row per match, per ingest run.
    SELECT
        _pulled_at,
        unnest(payload.matches) AS m
    FROM read_json('data/raw/matches/*.json')
),

renamed AS (
    -- Step 2 + 3: pick the fields we want, give them clear names and types.
    SELECT
        m.id::INTEGER                       AS match_id,
        m.season.id::INTEGER                AS season_id,
        m.matchday::INTEGER                 AS matchday,
        m.utcDate::TIMESTAMP                AS kickoff_utc,
        m.status                            AS status,

        m.homeTeam.id::INTEGER              AS home_team_id,
        m.homeTeam.shortName                AS home_team,
        m.awayTeam.id::INTEGER              AS away_team_id,
        m.awayTeam.shortName                AS away_team,

        m.score.fullTime.home::INTEGER      AS home_goals,
        m.score.fullTime.away::INTEGER      AS away_goals,
        m.score.halfTime.home::INTEGER      AS home_goals_ht,
        m.score.halfTime.away::INTEGER      AS away_goals_ht,

        -- Standardize the result into one short code: H / D / A (null if not played)
        CASE m.score.winner
            WHEN 'HOME_TEAM' THEN 'H'
            WHEN 'DRAW'      THEN 'D'
            WHEN 'AWAY_TEAM' THEN 'A'
        END                                 AS result,

        (m.score.fullTime.home + m.score.fullTime.away)::INTEGER AS total_goals,

        m.lastUpdated::TIMESTAMP            AS source_updated_at,
        _pulled_at                          AS pulled_at
    FROM raw
)

-- Step 4: deduplicate.
-- ROW_NUMBER numbers each copy of a match, newest first (1 = newest).
-- QUALIFY keeps only the rows where that number is 1.
SELECT *
FROM renamed
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY match_id
    ORDER BY source_updated_at DESC, pulled_at DESC
) = 1
ORDER BY kickoff_utc, match_id
