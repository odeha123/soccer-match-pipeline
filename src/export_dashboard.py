"""
Station 5: Export the marts to CSV for the Tableau dashboard.

Only runs after every data quality check has passed (see run_pipeline.py).
The CSVs live in dashboard/ and ARE committed to Git, so the dashboard
data is versioned and GitHub Actions can publish fresh files every day.

Run it with:  python src/export_dashboard.py
"""
from pathlib import Path

import duckdb

MARTS_DIR = Path("data/marts")
OUT_DIR = Path("dashboard")
OUT_DIR.mkdir(exist_ok=True)

con = duckdb.connect()

for parquet in sorted(MARTS_DIR.glob("mart_*.parquet")):
    out_path = OUT_DIR / f"{parquet.stem}.csv"
    con.sql(f"COPY (SELECT * FROM '{parquet}') TO '{out_path}' (HEADER, DELIMITER ',')")
    rows = con.sql(f"SELECT count(*) FROM '{parquet}'").fetchone()[0]
    print(f"Exported {parquet.stem}: {rows} rows -> {out_path}")
