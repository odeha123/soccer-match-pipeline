# Soccer Match Analytics Pipeline

An automated, end-to-end data pipeline that pulls English Premier League data from a public API every day, lands it raw, cleans and deduplicates it with SQL, models it into analytics-ready tables, verifies it with data quality checks, and publishes the results for a Tableau dashboard.

## Architecture

```
football-data.org API
        │  Python (requests, retry on rate limit)
        ▼
 1. RAW        data/raw/<endpoint>/<timestamp>.json   untouched API responses + pull timestamp
        │  DuckDB SQL
        ▼
 2. STAGING    stg_matches, stg_teams                 flattened, typed, deduplicated (latest pull wins)
        │  DuckDB SQL
        ▼
 3. MARTS      int_team_matches (one row per team per match)
               mart_home_away     home vs away performance
               mart_team_form     rolling last-5 form (window functions)
               mart_standings     league table after every matchday
        │
        ▼
 4. CHECKS     8 SQL data quality checks, logged every run; any failure stops the pipeline
        │
        ▼
 5. EXPORT     dashboard/*.csv  →  Tableau dashboard
```

The whole pipeline runs daily on **GitHub Actions** (`.github/workflows/pipeline.yml`) and commits the refreshed dashboard files and check log back to this repo.

## Stack

Python · SQL · DuckDB · Parquet · GitHub Actions · Tableau

## Data quality checks

Each check is a SQL query that returns the rows breaking a rule, so **zero rows = pass**. Results are appended to `data/logs/check_log.csv`, and any failure stops the pipeline **before** the dashboard files are updated.

| Dimension | Check |
|---|---|
| Uniqueness | `unique_match_id`, `unique_team_id` (prevents join fan-out) |
| Completeness | `finished_matches_have_scores`, `standings_complete` |
| Validity | `no_negative_scores`, `valid_match_dates` |
| Consistency | `result_matches_score` (H/D/A agrees with the score) |
| Reconciliation | `standings_match_api`: my calculated league table must match the API's official table |

Each check was validated by temporarily loosening its rule to confirm it flags bad rows.

## Design decisions

- **Raw data is never edited.** Every response is saved as-is with a `_pulled_at` timestamp, so transformations can be replayed after a bug fix and any number can be audited back to its source.
- **Idempotent, deduplicated loads.** Every run pulls the full season; staging keeps only the latest version of each match (`ROW_NUMBER()` by `match_id`, ordered by the source's `lastUpdated`) and each team. Re-running never creates duplicates.
- **One row per team per match.** `int_team_matches` uses `UNION ALL` to view every match from both teams' perspectives, which makes every mart a simple `GROUP BY team`.
- **Checks gate publishing.** The export step only runs after every check passes.
- **Reconciliation against an independent source.** Standings are computed from match results, then tied back to the API's official table.

## Project structure

```
src/
  ingest.py            1. API -> raw JSON
  build_staging.py     2. runs sql/staging/*.sql
  build_marts.py       3. runs sql/marts/*.sql (int_ first, then mart_)
  run_checks.py        4. runs sql/checks/*.sql, logs results, fails on any bad rows
  export_dashboard.py  5. marts -> dashboard/*.csv
  run_pipeline.py      runs 1-5 in order, stops on failure
sql/
  staging/  marts/  checks/
dashboard/             CSVs for Tableau (refreshed daily)
data/logs/             data quality check history
```

## Run it locally

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env                       # add your free football-data.org API key
python src/run_pipeline.py                 # full run
python src/run_pipeline.py --skip-ingest   # rebuild from existing raw data, no API call
```

Data provided by [football-data.org](https://www.football-data.org).
