"""
Phase 3 warm-up: query the raw JSON files with SQL, using DuckDB.

DuckDB can read JSON files directly, so we can explore our raw data with SQL
before building any tables. Each query below teaches one idea.

Run it with:  python src/explore_raw.py
"""
import duckdb

con = duckdb.connect()  # an in-memory database: nothing is saved yet


def show(title, sql):
    print(f"\n=== {title} ===")
    con.sql(sql).show()


# Query 1: read_json turns each file into one row. Our matches are hidden
# inside payload.matches as a LIST, so there's only one row per file.
show("1. One row per raw file", """
    SELECT _pulled_at, len(payload.matches) AS n_matches
    FROM read_json('data/raw/matches/*.json')
""")

# Query 2: UNNEST explodes a list into rows: one row per match.
# The dot syntax (m.homeTeam.shortName) reaches into nested objects.
show("2. UNNEST: one row per match (first 5)", """
    WITH matches AS (
        SELECT unnest(payload.matches) AS m
        FROM read_json('data/raw/matches/*.json')
    )
    SELECT
        m.id                    AS match_id,
        m.matchday,
        m.status,
        m.homeTeam.shortName    AS home_team,
        m.score.fullTime.home   AS home_goals,
        m.score.fullTime.away   AS away_goals,
        m.awayTeam.shortName    AS away_team
    FROM matches
    ORDER BY m.utcDate
    LIMIT 5
""")

# Query 3: GROUP BY. How many matches are in each status?
show("3. Matches by status", """
    WITH matches AS (
        SELECT unnest(payload.matches) AS m
        FROM read_json('data/raw/matches/*.json')
    )
    SELECT m.status, count(*) AS n_matches
    FROM matches
    GROUP BY m.status
    ORDER BY n_matches DESC
""")

# Query 4: your turn to read. What does this one answer?
show("4. ???", """
    WITH matches AS (
        SELECT unnest(payload.matches) AS m
        FROM read_json('data/raw/matches/*.json')
    )
    SELECT
        count(*) FILTER (WHERE m.score.winner = 'HOME_TEAM') AS home_wins,
        count(*) FILTER (WHERE m.score.winner = 'DRAW')      AS draws,
        count(*) FILTER (WHERE m.score.winner = 'AWAY_TEAM') AS away_wins
    FROM matches
    WHERE m.status = 'FINISHED'
""")
