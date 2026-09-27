"""
The whole pipeline, one command.

Runs each station in order. If any station fails, the pipeline STOPS,
so bad data never flows further down the line.

    Station 1  ingest.py          API -> data/raw/          (get data)
    Station 2  build_staging.py   raw -> data/staging/      (clean data)
    Station 3  run_checks.py      checks staging tables     (verify data)
    Station 4  build_marts.py     staging -> data/marts/    (analyze data)  <- coming next

Run everything:                   python src/run_pipeline.py
Skip the API call (rebuild only): python src/run_pipeline.py --skip-ingest
"""
import subprocess
import sys
import time

# The assembly line, in order. Each entry: (station name, script to run)
STATIONS = [
    ("1. Ingest",  "src/ingest.py"),
    ("2. Staging", "src/build_staging.py"),
    ("3. Checks",  "src/run_checks.py"),
]

skip_ingest = "--skip-ingest" in sys.argv
start = time.time()

for name, script in STATIONS:
    if skip_ingest and script == "src/ingest.py":
        print(f"\n===== {name}: skipped (--skip-ingest) =====", flush=True)
        continue

    print(f"\n===== {name}: {script} =====", flush=True)

    # Run the script with the same Python we're using (our .venv).
    result = subprocess.run([sys.executable, script])

    # Every script exits with code 0 on success, anything else on failure.
    if result.returncode != 0:
        print(f"\nPIPELINE STOPPED: {name} failed. Later stations did not run.")
        sys.exit(1)

print(f"\nPIPELINE SUCCEEDED in {time.time() - start:.1f}s")
