# Soccer Match Analytics Pipeline

> 🚧 **In progress.** Building this in public, one layer at a time.

An end-to-end data pipeline that pulls English Premier League data from a public API, lands it raw, cleans and deduplicates it with SQL, and models it into analytics-ready tables for a Tableau dashboard.

## Architecture

```
football-data.org API
        │  Python (requests)
        ▼
  Raw layer      data/raw/<endpoint>/<timestamp>.json    untouched API responses + pull timestamp
        │  DuckDB SQL
        ▼
  Staging layer  data/staging/stg_*.parquet              flattened, typed, deduplicated
        │  DuckDB SQL
        ▼
  Marts layer    team form · home vs away · standings    (coming next)
        │
        ▼
  Tableau dashboard                                       (planned)
```

## Stack

Python · SQL · DuckDB · Parquet · GitHub Actions (planned) · Tableau (planned)

## Status

| Layer | Status |
|---|---|
| API ingestion (matches, standings, teams) with rate-limit retry | ✅ Done |
| Raw landing zone with pull timestamps | ✅ Done |
| `stg_matches`: flatten, type, derive result, deduplicate | ✅ Done |
| Data quality checks + run logging | ⏳ Next |
| Marts: team form, home vs away, standings by matchday | ⏳ Planned |
| Scheduled runs with GitHub Actions | ⏳ Planned |
| Tableau dashboard | ⏳ Planned |

## Design decisions

- **Raw data is never edited.** Every API response is saved as-is with a `_pulled_at` timestamp, so transformations can be replayed after a bug fix, any number can be audited back to its source, and history builds up that the API doesn't keep.
- **Deduplication in staging.** Each ingest run re-downloads the full season, so `stg_matches` keeps only the latest version of each match (`ROW_NUMBER()` over `match_id`, ordered by the source's `lastUpdated`).
- **Grain:** `stg_matches` has one row per match.

## Run it locally

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env               # add your free football-data.org API key
python src/ingest.py               # pull raw data
python src/build_staging.py        # build staging tables
python src/check_duplicates.py     # verify no duplicate matches
```

Data provided by [football-data.org](https://www.football-data.org).
