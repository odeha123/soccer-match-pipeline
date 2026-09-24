"""
Phase 2: Ingest.

Pulls Premier League data from football-data.org and saves each API response
EXACTLY as it came back (raw JSON), stamped with the time we pulled it.

Why save it untouched? If we find a bug in our cleaning logic later, we can
re-run the cleaning on these raw files instead of calling the API again.
This "raw landing zone" is the first layer of the medallion architecture.

Run it with:  python src/ingest.py
"""
import json
import os
import time
from datetime import datetime, timezone
from pathlib import Path

import requests
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv("FOOTBALL_DATA_API_KEY")
if not API_KEY or API_KEY == "your_key_here":
    raise SystemExit("No API key found in .env")

BASE_URL = "https://api.football-data.org/v4"
COMPETITION = "PL"
RAW_DIR = Path("data/raw")

# The three things we pull. Each name becomes a folder under data/raw/.
ENDPOINTS = {
    "matches":   f"/competitions/{COMPETITION}/matches",
    "standings": f"/competitions/{COMPETITION}/standings",
    "teams":     f"/competitions/{COMPETITION}/teams",
}


def fetch(path: str) -> dict:
    """Call one API endpoint and return the JSON. Retries if we hit the rate limit."""
    url = BASE_URL + path
    for attempt in range(1, 4):  # try up to 3 times
        response = requests.get(url, headers={"X-Auth-Token": API_KEY}, timeout=30)

        if response.status_code == 429:  # 429 = "Too Many Requests"
            wait = int(response.headers.get("X-RequestCounter-Reset", 60))
            print(f"  Rate limited. Waiting {wait}s (attempt {attempt}/3)...")
            time.sleep(wait)
            continue

        response.raise_for_status()  # any other error: stop and show it
        return response.json()

    raise RuntimeError(f"Gave up on {url} after 3 attempts")


def save_raw(name: str, data: dict, pulled_at: datetime) -> Path:
    """Save one response to data/raw/<name>/<timestamp>.json"""
    folder = RAW_DIR / name
    folder.mkdir(parents=True, exist_ok=True)
    file_path = folder / f"{pulled_at.strftime('%Y-%m-%dT%H%M%SZ')}.json"

    # Wrap the API response with metadata about THIS pull
    record = {
        "_pulled_at": pulled_at.isoformat(),
        "_source": BASE_URL + ENDPOINTS[name],
        "payload": data,
    }
    file_path.write_text(json.dumps(record, indent=2))
    return file_path


def main():
    pulled_at = datetime.now(timezone.utc)  # one timestamp for the whole run
    print(f"Ingest run started at {pulled_at.isoformat()}")

    for name, path in ENDPOINTS.items():
        data = fetch(path)
        saved_to = save_raw(name, data, pulled_at)
        print(f"  {name:<10} -> {saved_to}")

    print("Done.")


if __name__ == "__main__":
    main()
