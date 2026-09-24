"""
Step 1: Explore the football-data.org API.

Goal: make one real request, see what the JSON looks like,
and check how many requests we have left this minute.
Run it with:  python src/explore_api.py
"""
import json
import os

import requests
from dotenv import load_dotenv

# 1. Read the API key from the .env file (so it never lives in our code)
load_dotenv()
API_KEY = os.getenv("FOOTBALL_DATA_API_KEY")
if not API_KEY or API_KEY == "your_key_here":
    raise SystemExit("No API key found. Did you create .env and paste your key?")

# 2. Build the request. The API wants the key in a header called X-Auth-Token.
BASE_URL = "https://api.football-data.org/v4"
headers = {"X-Auth-Token": API_KEY}

# 3. Ask for every Premier League match in the current season
response = requests.get(f"{BASE_URL}/competitions/PL/matches", headers=headers, timeout=30)
print("Status code:", response.status_code)  # 200 = success
print("Requests left this minute:", response.headers.get("X-Requests-Available-Minute"))

response.raise_for_status()  # stop with an error if the request failed
data = response.json()       # turn the JSON text into a Python dictionary

# 4. Look at what came back
print("Top-level keys:", list(data.keys()))
print("Season:", data["filters"].get("season"), "| Matches returned:", len(data["matches"]))

print("\nOne match, in full:")
print(json.dumps(data["matches"][0], indent=2))
