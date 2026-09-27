"""
Phase 6: Data quality checks + run logging.

Every .sql file in sql/checks/ is a query that returns BAD rows.
  0 rows  -> PASS
  1+ rows -> FAIL (and we print the bad rows so you can investigate)

Each run is appended to data/logs/check_log.csv so there's a history
of every check, every time the pipeline ran.

Run it with:  python src/run_checks.py
"""
import csv
import sys
from datetime import datetime, timezone
from pathlib import Path

import duckdb

CHECKS_DIR = Path("sql/checks")
LOG_FILE = Path("data/logs/check_log.csv")
LOG_FILE.parent.mkdir(parents=True, exist_ok=True)

run_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
con = duckdb.connect()
results = []

print(f"Data quality checks, {run_at}\n")

for sql_file in sorted(CHECKS_DIR.glob("*.sql")):
    name = sql_file.stem
    query = sql_file.read_text()

    # Skip check files that only contain comments (not written yet)
    has_sql = any(line.strip() and not line.strip().startswith("--")
                  for line in query.splitlines())
    if not has_sql:
        print(f"  SKIP  {name}  (no query written yet)")
        results.append((name, "SKIP", ""))
        continue

    try:
        bad_rows = con.sql(query)
        n_bad = len(bad_rows.fetchall())
    except Exception as err:
        print(f"  ERROR {name}: {err}")
        results.append((name, "ERROR", ""))
        continue

    status = "PASS" if n_bad == 0 else "FAIL"
    print(f"  {status}  {name}  ({n_bad} bad rows)")
    if n_bad:
        bad_rows.show(max_rows=10)
    results.append((name, status, n_bad))

# Append this run to the log
is_new = not LOG_FILE.exists() or LOG_FILE.stat().st_size == 0
with LOG_FILE.open("a", newline="") as f:
    writer = csv.writer(f)
    if is_new:
        writer.writerow(["run_at", "check", "status", "bad_rows"])
    for name, status, n_bad in results:
        writer.writerow([run_at, name, status, n_bad])

n_fail = sum(1 for _, s, _ in results if s in ("FAIL", "ERROR"))
print(f"\n{len(results)} checks, {n_fail} failed. Logged to {LOG_FILE}")

# Exit with an error code if anything failed. GitHub Actions will use this later
# to mark the run red and stop bad data from reaching the dashboard.
sys.exit(1 if n_fail else 0)
