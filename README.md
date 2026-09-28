# Soccer Match Pipeline

A data pipeline that collects Premier League match data every day, cleans it, and turns it into tables for a Tableau dashboard showing the league table over time, each team's recent form, and how teams perform at home compared to away.

I built it to practise the full process a data team goes through: getting raw data from a source, cleaning it, checking that it can be trusted, and making it ready for analysis.

## How it works

The pipeline runs in five steps. `src/run_pipeline.py` runs them in order, and GitHub Actions runs that script automatically every morning.

1. **Collect.** `src/ingest.py` pulls matches, teams and standings from the [football-data.org](https://www.football-data.org) API. Each response is saved exactly as it arrived, with the time it was pulled, so I can always go back to the original data.

2. **Clean.** The SQL in `sql/staging/` flattens the API's nested JSON into simple tables, gives the columns clear names and types, and removes duplicates. Every run downloads the full season again, so only the most recent copy of each match and team is kept.

3. **Model.** The SQL in `sql/marts/` builds the tables the dashboard uses:
   - a league table after every matchday
   - each team's last five results
   - home vs. away records for every team

4. **Check.** The SQL in `sql/checks/` looks for problems, such as duplicate matches, finished matches with no score, a result that doesn't match the score, or impossible dates. One check compares my calculated league table with the official one from the API to make sure they agree. Results are saved to `data/logs/check_log.csv`, and if any check fails the pipeline stops so bad data never reaches the dashboard.

5. **Export.** The final tables are saved as CSV files in `dashboard/` for Tableau.

## Tools

Python, SQL, DuckDB, Parquet, GitHub Actions, Tableau

## Running it yourself

You'll need a free API key from football-data.org.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # then paste your API key into .env
python src/run_pipeline.py
```
