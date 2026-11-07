# qdbd-dbt-demo

A dbt project on DuckDB, built so [qdbd](https://qdbd.dev/) has something real to draw. The ERD in `erd/` is written by hand. Descriptions and column types come from the dbt yml, through one `# @dbt: ..` line, with no `manifest.json`. CI fails when the two disagree. Each environment (dev, qa, prod) publishes its own diagram, and qa and dev highlight what promoting them would change.

The data is a sample of the Skytrax reviews from [skytrax_reviews_data](https://github.com/MarkPhamm/skytrax_reviews_data), modelled the same way: four star schemas on one shared set of dimensions. The CI/CD follows [dbt_duckdb_cicd_template](https://github.com/MarkPhamm/dbt_duckdb_cicd_template).

## Setup

Python 3.12 and [uv](https://docs.astral.sh/uv/). qdbd 0.6.0, the same pin as CI:

```bash
uv sync
uv tool install "quickdbd-cli==0.6.0"
uv run dbt deps
uv run dbt build
qdbd serve erd
```

`profiles.yml` is committed because DuckDB has no credentials. dbt reads it from the project directory.

## Layout

```
data/raw/            Skytrax sample, read in place by a dbt source (read_csv)
models/
  staging/           stg_skytrax__*         one per raw file, re-ingested duplicates removed
  intermediate/      int_*_reviews_cleaned  nulls to 'unknown', casts, normalised spellings
  conformed/         dim_airline, dim_customer, dim_aircraft, dim_date
  airline_reviews/   fct_airline_review, dim_location
  airport_reviews/   fct_airport_review, dim_airport
  lounge_reviews/    fct_lounge_review, dim_lounge
  seat_reviews/      fct_seat_review, dim_seat_configuration
erd/                 the diagram, one .txt per star schema
scripts/sample_raw.py  rebuilds data/raw/ from a skytrax_reviews_data checkout
```

Each star schema is a folder straight under `models/`, so it is also a schema in prod (`conformed`, `lounge_reviews`, ...). [GLOSSARY.md](GLOSSARY.md) defines review, reviewer, rating band and the rest.

## Data model

Grain of every fact: one row per review submission. Row counts are for the committed sample.

| Folder | Table | Rows | |
|---|---|---:|---|
| conformed | `dim_airline` | 595 | Airline lookup, shared by airline, lounge and seat reviews |
| conformed | `dim_customer` | 1,533 | Reviewer proxy (name + nationality), with a review count per subject |
| conformed | `dim_aircraft` | 44 | Model, manufacturer, seat capacity |
| conformed | `dim_date` | 21,130 | Calendar and fiscal spine covering every date in every fact |
| airline_reviews | `fct_airline_review` | 500 | 7 category ratings, origin / destination / transit location |
| airline_reviews | `dim_location` | 334 | City + airport code, role-played three times by the fact |
| airport_reviews | `fct_airport_review` | 500 | 8 category ratings |
| airport_reviews | `dim_airport` | 1,004 | Airport lookup |
| lounge_reviews | `fct_lounge_review` | 482 | 7 category ratings |
| lounge_reviews | `dim_lounge` | 403 | Lounge, airport and access tier |
| seat_reviews | `fct_seat_review` | 483 | 12 category ratings |
| seat_reviews | `dim_seat_configuration` | 29 | Cabin, normalised layout, seats per row |

`scripts/sample_raw.py` keeps the 480 most recent submissions per subject, plus up to 20 that the source stored twice, so the staging dedup still has something to remove. One seat-review test warns on purpose: three reviews in the source carry a 1970 submission date.

Skytrax reviews are self-reported. Anything built on them is directional, not population-level.

## The diagram

`erd/` is five files, one per star schema. qdbd compiles the folder as one schema, so `fct_lounge_review` in `lounge_reviews.txt` can point at `dim_customer` in `conformed.txt`.

The tables, columns and relationships are written by hand. Everything else comes from the yml, through `# @dbt: ..` at the top of `erd/conformed.txt`:

| In the diagram | From |
|---|---|
| Table description | the model's `description` |
| Column description | the column's `description`; `average_rating` and `rating_band` come from `{% docs %}` blocks in `models/docs.md` |
| Column type | the column's `data_type` |
| Header colour | the name: `dim_` and `fct_` are tagged and coloured without any config |

`qdbd check --strict erd` fails when they drift: a column in the diagram that the yml does not list, a yml column missing from the diagram, a type that disagrees, or a table with no dbt model. `dim_route` in `erd/airline_reviews.txt` is planned and not built. `# @dbt: none` above it keeps the check quiet.

```bash
qdbd serve erd                     # then open fct_lounge_review
qdbd check --strict erd
qdbd build erd -o /tmp/erd.html
qdbd build erd -s group:lounge_reviews -o /tmp/lounge.html
qdbd path erd --from dim_customer --to fct_seat_review
```

Positions live in `erd/qdbd.layout.json`. `qdbd layout --by-group erd` rewrites them with one region per file.

## Environments

One `database/database.duckdb`. The target chooses the schema.

| Target | Used by | Schema |
|---|---|---|
| `dev` (default) | your laptop, CD on the `dev` branch | `dev`, everything flat |
| `qa` | CD on the `qa` branch | `qa`, everything flat |
| `ci` | pull requests | `ci_local`, or `ci_pr_<n>` when `DBT_CI_SCHEMA` is set |
| `prod` | CD on `main` | `staging`, `intermediate`, `conformed`, and one per subject |

`macros/generate_schema_name.sql` is what makes prod split and the others stay flat. dbt's built-in macro would concatenate instead (`dev_staging`).

## Branches and promotion

Changes move `feature → dev → qa → main`, one pull request per hop.

| Branch | Ahead of the next one by | Pages |
|---|---|---|
| `main` | (production) | `/` |
| `qa` | `dim_cabin`, a conformed dimension, with `cabin_id` on the airline and seat facts | `/qa/`, coloured against `main` |
| `dev` | `dim_route` built as a model, with `route_id` on `fct_airline_review` | `/dev/`, coloured against `qa` |

On `qa` or `dev`:

```bash
qdbd diff --base main erd
qdbd build erd --diff-base main -o /tmp/erd-diff.html
```

## CI/CD

`cd.yml` runs on a push to `dev`, `qa` or `main`. It builds that branch's target (`main` builds `prod`) and uploads `manifest.json` and `database.duckdb` as `dbt-artifacts`.

`ci.yml` runs on a pull request into any of the three:

- `slim-ci` downloads the artifact from the base branch's last green `cd.yml` and runs `dbt build --target ci --select state:modified+ --defer`. A pull request into `qa` is compared with `qa`, not with prod. Each branch needs one green `cd.yml` run before pull requests into it can download anything.
- `erd` runs `qdbd check --strict erd` and posts one comment with what the pull request changes in the diagram. It needs no dbt, no build and no manifest.

`pages.yml` runs after each successful `cd.yml`. It checks out all three branches, builds `erd/` on each one (`qa` with `--diff-base main`, `dev` with `--diff-base qa`), and deploys the result to GitHub Pages. Set **Settings → Pages → Source** to **GitHub Actions** once.

## Refreshing the sample

```bash
uv run python scripts/sample_raw.py ../skytrax_reviews_data/data/raw
```

## Elsewhere in qdbd

This repo does not set these up. The docs do:

- [Importing a dbt manifest](https://qdbd.dev/dbt/) instead of linking the yml
- [MCP](https://qdbd.dev/mcp/) for agents
- [Sharing a gist](https://qdbd.dev/sharing/)
- [DBML](https://qdbd.dev/dbml/)
- [PNG, SVG and draw.io](https://qdbd.dev/exports/)
- [VS Code](https://qdbd.dev/vscode/)
