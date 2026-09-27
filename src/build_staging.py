"""
Phase 4: Build staging tables.

Runs every .sql file in sql/staging/ and saves each result as a Parquet file
in data/staging/. The file name becomes the table name (stg_matches.sql -> stg_matches.parquet).

Run it with:  python src/build_staging.py
"""
from pathlib import Path

import duckdb

SQL_DIR = Path("sql/staging")
OUT_DIR = Path("data/staging")
OUT_DIR.mkdir(parents=True, exist_ok=True)

con = duckdb.connect()

for sql_file in sorted(SQL_DIR.glob("*.sql")):
    table = sql_file.stem                     # "stg_matches"
    out_path = OUT_DIR / f"{table}.parquet"

    query = sql_file.read_text()
    con.sql(f"COPY ({query}) TO '{out_path}' (FORMAT parquet)")

    rows = con.sql(f"SELECT count(*) FROM '{out_path}'").fetchone()[0]
    print(f"Built {table}: {rows} rows -> {out_path}")

# Quick peek at the result
print("\nSample of stg_matches:")
con.sql("""
    SELECT matchday, kickoff_utc, home_team, home_goals, away_goals, away_team, result
    FROM 'data/staging/stg_matches.parquet'
    WHERE status = 'FINISHED'
    LIMIT 5
""").show()
