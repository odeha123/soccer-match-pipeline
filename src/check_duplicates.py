"""
Experiment: prove that staging removes duplicates.

Compares how many match rows are in the RAW files (every copy from every run)
with how many are in STAGING (one row per match).

Run it with:  python src/check_duplicates.py
"""
import duckdb

raw_files = duckdb.sql("SELECT count(*) FROM glob('data/raw/matches/*.json')").fetchone()[0]

raw_rows = duckdb.sql("""
    SELECT count(*) FROM (
        SELECT unnest(payload.matches) FROM read_json('data/raw/matches/*.json')
    )
""").fetchone()[0]

stg_rows, stg_unique = duckdb.sql("""
    SELECT count(*), count(DISTINCT match_id)
    FROM 'data/staging/stg_matches.parquet'
""").fetchone()

print(f"Raw files (ingest runs):   {raw_files}")
print(f"Match rows in raw:         {raw_rows}")
print(f"Match rows in staging:     {stg_rows}")
print(f"Unique match_ids:          {stg_unique}")
print("PASS: no duplicates in staging" if stg_rows == stg_unique else "FAIL: duplicates found")
