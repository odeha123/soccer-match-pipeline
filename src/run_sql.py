"""
Practice tool: run any .sql file and print the result (nothing is saved).

Run it with:  python src/run_sql.py sql/staging/stg_teams.sql
"""
import sys
from pathlib import Path

import duckdb

if len(sys.argv) != 2:
    raise SystemExit("Usage: python src/run_sql.py <path to .sql file>")

query = Path(sys.argv[1]).read_text()
result = duckdb.sql(query)
result.show(max_rows=30, max_width=200)
print(f"{len(result.fetchall())} rows")
