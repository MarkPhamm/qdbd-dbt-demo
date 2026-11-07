"""Write a small, deterministic sample of the Skytrax raw tables to data/raw/.

The full extracts live in skytrax_reviews_data (about 240 MB). The diagram and
the tests only need the shape of the data, so this repo commits a sample:

- for each review table, the 480 most recent submissions, plus up to 20 that
  the scrape re-ingested under a second review_id, so the staging dedup and
  its unique_combination_of_columns test still have duplicates to remove;
- every row of those submissions, duplicates included;
- the airlines and airports lookups in full, so every foreign key resolves.

Columns are read and written as text, so values keep the source's spelling.

Usage:
    uv run python scripts/sample_raw.py [SKYTRAX_RAW_DIR]
"""

import sys
from pathlib import Path

import duckdb

SUBMISSIONS = 500
DUPLICATED = 20

# What identifies a submission, as in models/staging/stg_skytrax__*.sql.
SUBMISSION_KEYS = {
    "airline_reviews": ["customer_name", "nationality", "airline_id", "date_submitted", "review"],
    "airport_reviews": ["customer_name", "nationality", "airport_id", "date_submitted", "review"],
    "lounge_reviews": ["customer_name", "nationality", "airline_id", "lounge_name", "date_submitted", "review"],
    "seat_reviews": ["customer_name", "nationality", "airline_id", "date_submitted", "review"],
}
LOOKUPS = ["airlines", "airports"]


def source_file(raw_dir: Path, name: str) -> Path:
    # skytrax tracks the largest table gzipped; DuckDB reads either.
    for candidate in (raw_dir / f"{name}.csv", raw_dir / f"{name}.csv.gz"):
        if candidate.exists():
            return candidate
    sys.exit(f"{name}.csv(.gz) not found in {raw_dir}")


def main() -> None:
    raw_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "../skytrax_reviews_data/data/raw")
    out_dir = Path(__file__).resolve().parent.parent / "data" / "raw"
    out_dir.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect()

    for name in LOOKUPS:
        src = source_file(raw_dir, name)
        con.execute(
            f"copy (select * from read_csv('{src}', header = true, all_varchar = true)) "
            f"to '{out_dir / name}.csv' (header)"
        )

    for name, keys in SUBMISSION_KEYS.items():
        src = source_file(raw_dir, name)
        key_list = ", ".join(keys)
        # `is not distinct from` so a null customer_name still matches itself.
        key_match = " and ".join(f"r.{k} is not distinct from p.{k}" for k in keys)
        con.execute(f"""
            copy (
                with raw as (
                    select * from read_csv('{src}', header = true, all_varchar = true)
                ),
                submissions as (
                    select {key_list}, count(*) > 1 as is_duplicated, min(review_id::integer) as first_id
                    from raw
                    group by all
                ),
                picked as (
                    (select * from submissions where is_duplicated
                     order by date_submitted desc, first_id limit {DUPLICATED})
                    union all
                    (select * from submissions where not is_duplicated
                     order by date_submitted desc, first_id limit {SUBMISSIONS - DUPLICATED})
                )
                select r.*
                from raw as r
                semi join picked as p on {key_match}
                order by r.review_id::integer
            ) to '{out_dir / name}.csv' (header)
        """)

    for path in sorted(out_dir.glob("*.csv")):
        rows = con.execute(f"select count(*) from read_csv('{path}', header = true, all_varchar = true)").fetchone()[0]
        print(f"{path.relative_to(out_dir.parent.parent)}: {rows} rows")


if __name__ == "__main__":
    main()
