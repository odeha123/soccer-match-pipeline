"""
Station 4: Build marts (analytics-ready tables).

Runs the SQL files in sql/marts/ and saves each as Parquet in data/marts/.
  * int_*.sql files (intermediate building blocks) are built FIRST,
    because the mart_*.sql files read from them.
  * Files that only contain comments (not written yet) are skipped.

Run it with:  python src/build_marts.py
"""
from pathlib import Path

import duckdb

SQL_DIR = Path("sql/marts")
OUT_DIR = Path("data/marts")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Build order: intermediates first, then marts
files = sorted(SQL_DIR.glob("int_*.sql")) + sorted(SQL_DIR.glob("mart_*.sql"))

con = duckdb.connect()

for sql_file in files:
    table = sql_file.stem
    query = sql_file.read_text()

    has_sql = any(line.strip() and not line.strip().startswith("--")
                  for line in query.splitlines())
    if not has_sql:
        print(f"SKIP  {table}  (no query written yet)")
        continue

    out_path = OUT_DIR / f"{table}.parquet"
    con.sql(f"COPY ({query}) TO '{out_path}' (FORMAT parquet)")
    rows = con.sql(f"SELECT count(*) FROM '{out_path}'").fetchone()[0]
    print(f"Built {table}: {rows} rows -> {out_path}")
