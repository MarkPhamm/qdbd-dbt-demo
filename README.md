# qdbd-dbt-demo

A working demo of [qdbd](https://qdbd.dev/) on a real dbt project. Four star schemas on DuckDB, a hand-written ERD in `erd/`, and one `# @dbt:` line that pulls descriptions, tags and column types straight from the dbt yml. CI checks the diagram against the yml, every pull request gets a schema diff, and each environment publishes its own diagram.

**Live diagrams:** [production](https://markphamm.github.io/qdbd-dbt-demo/) · [qa vs main](https://markphamm.github.io/qdbd-dbt-demo/qa/) · [dev vs qa](https://markphamm.github.io/qdbd-dbt-demo/dev/)

[![The production ER diagram in qdbd: four star schemas in shaded regions around the conformed dimensions](docs/images/qdbd-overview.png)](https://markphamm.github.io/qdbd-dbt-demo/)

_The production diagram: one shaded region per file under `erd/`, mirroring the folders under `models/`. Click any table for its dbt descriptions, types, tags and relationships._

The data is a sample of the Skytrax reviews from [skytrax_reviews_data](https://github.com/MarkPhamm/skytrax_reviews_data), modelled the same way: four star schemas on one shared set of dimensions. The CI/CD follows [dbt_duckdb_cicd_template](https://github.com/MarkPhamm/dbt_duckdb_cicd_template).

## What qdbd does

[qdbd](https://qdbd.dev/) keeps a database diagram as plain text in the repo — QuickDBD syntax or DBML — and builds it into one interactive HTML page. It checks the schema, lays it out, renders it, and compares versions. No database connection, no diagram-tool account, and no second copy of the schema to keep in sync.

For a dbt project, one line connects the two:

```text
# @dbt: ../..
```

qdbd reads the project's `.yml` and `.md` files directly and adds their descriptions, column types and tags to the diagram. No `manifest.json`, no `dbt parse`, no build. That is the whole integration used here; the [dbt guide](https://qdbd.dev/dbt/) covers the manifest route for projects that prefer it.

What that gives this repo:

- **The diagram is reviewed like code.** `erd/` holds five hand-written files, one per schema: the four star schemas and the conformed dimensions. A model change and its diagram change land in the same pull request.
- **dbt stays the source of truth for documentation.** Descriptions, `pii` tags and column types come from the yml. The picture cannot quietly drift from the docs.
- **Drift fails the build.** `qdbd check --strict erd` fails when a column exists on one side only, a type changes base type, or a table has no model.
- **A branch shows what merging it changes.** `qdbd diff` lists it, `qdbd build --diff-base` colours it, and the GitHub Action posts it on the pull request.
- **The same schema answers questions.** `qdbd path` returns the shortest join and its SQL; `qdbd mcp` serves tables, keys and paths to an AI agent.

| I want to… | Command | In this repo |
|---|---|---|
| Browse and edit the diagram | `qdbd serve erd` | local live editor; dragged positions go to `erd/qdbd.layout.json` |
| Build a shareable page | `qdbd build erd -o erd.html` | GitHub Pages, one page per environment |
| Catch diagram/yml drift | `qdbd check --strict erd` | `ci.yml` › `erd` |
| See a branch's schema diff | `qdbd diff --base main erd` | pull-request comment and coloured diagram |
| Find a join | `qdbd path erd --from dim_customer --to fct_seat_review` | prints the shortest path and `FROM`/`JOIN` SQL |
| Export for a doc or slide | `qdbd export erd -o erd.svg` | PNG, SVG and draw.io |
| Let an agent read the schema | `qdbd mcp` | MCP over stdio |

### The yml, in the diagram

[![dim_customer in qdbd, filtered to tag:pii, with its dbt descriptions, pii tags and column types in the detail panel](docs/images/qdbd-dbt-metadata.png)](https://markphamm.github.io/qdbd-dbt-demo/#f=tag%3Apii&t=dim_customer&z=1.5&c=810%2C1140)

In the Filter box, `tag:pii` narrows 13 tables to `dim_customer`. Its table description, all ten column descriptions and the `varchar`/`bigint` types come from `models/conformed/_conformed__models.yml` and the `{% docs %}` blocks in `models/docs.md`. The `pii` tags tint `customer_name` and `nationality`; the same tags are what the filter matches.

### A branch shows what merging it changes

[![fct_airline_review selected on qa, marked CHANGED, with + cabin_id and - seat_type in the detail panel, and dim_cabin marked NEW](docs/images/qdbd-diff.png)](https://markphamm.github.io/qdbd-dbt-demo/qa/#t=fct_airline_review)

`/qa/` is built with `--diff-base main`. `dim_cabin` is green (new); `fct_airline_review` is amber (changed). Selecting the fact lists `+ cabin_id` and `- seat_type`; the banner counts the two new relationships. The same change is what the `erd` job comments on the promotion pull request.

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
erd/                 the diagram: erd/<star schema>/<star schema>.txt, mirroring models/
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

## The dbt link: `# @dbt:`

`erd/` is five hand-written files, one folder per schema. The four star schemas plus `conformed` mirror `models/`:

```
erd/
├── conformed/conformed.txt              # @dbt: ../..   <- the only link
├── airline_reviews/airline_reviews.txt
├── airport_reviews/airport_reviews.txt
├── lounge_reviews/lounge_reviews.txt
├── seat_reviews/seat_reviews.txt
└── qdbd.layout.json                     table positions for the whole diagram
```

`# @dbt: ../..` names the folder holding `dbt_project.yml`, relative to the file it sits in. qdbd then reads the project's yml and `.md` files directly and adds them to the diagram. No `manifest.json`, no `dbt parse`, no build.

One line is enough. `qdbd check erd` compiles every `.txt` under `erd/`, subfolders included, as one schema, and the link applies to that whole schema. So `fct_lounge_review` in `lounge_reviews/lounge_reviews.txt` gets its yml too, and can point at `dim_customer` in `conformed/conformed.txt`. Always pass the `erd` folder. `--each` or `--site` would make each subfolder its own schema: each would then need its own `# @dbt:` line, and every fact's FK to a conformed dimension would fail with `Invalid relationship, the table 'dim_customer' does not exist`.

Tables match dbt models by name, ignoring case. Columns match by name. Your `.txt` is never changed.

| What qdbd adds | Where to see it here |
|---|---|
| Table descriptions | Every table. `dim_customer` shows its yml description first, then the comment written above it in `erd/conformed/conformed.txt` |
| Column descriptions | Every column with one. `average_rating` and `rating_band` come from `{% docs %}` blocks in `models/docs.md` |
| Column types | Every column the `.txt` leaves untyped is filled from `data_type`. `fct_lounge_review.rating_band` is typed `varchar(7)` in the file, so it keeps that |
| Tags | `customer_name` and `nationality` are tagged `pii` in `models/conformed/_conformed__models.yml`, so their rows are tinted. Type `tag:pii` in the Filter box |

Header colours come from the names: `dim_` and `fct_` are tagged and coloured with no config.

### Drift warnings

Anything the `.txt` and the yml disagree on becomes a `dbt:` warning: a column on one side only, a type with a different base type, a table with no dbt model. Add `has_shower` under `staff_service` in `erd/lounge_reviews/lounge_reviews.txt`, then:

```console
$ qdbd check erd
erd/lounge_reviews/lounge_reviews.txt:18: warning: dbt: column 'has_shower' is not in the yml for 'fct_lounge_review' (models/lounge_reviews/_lounge_reviews__models.yml:26)
No errors found (1 warning(s)).
$ qdbd check --strict erd; echo $?
1
```

CI runs the strict check on every pull request.

On `main`, `dim_route` in `erd/airline_reviews/airline_reviews.txt` is planned, not built, and `# @dbt: none` above it keeps the check quiet. On this branch it is a model, so the line is gone and the yml describes it.

### Commands

```bash
qdbd serve erd                     # then open dim_customer
qdbd check --strict erd
qdbd build erd -o /tmp/erd.html
qdbd build erd -s group:lounge_reviews -o /tmp/lounge.html
qdbd path erd --from dim_customer --to fct_seat_review
```

`qdbd path` prints the path and the SQL, so the answer can go straight into a query:

```console
$ qdbd path erd --from dim_customer --to fct_seat_review
dim_customer -> fct_seat_review: 1 join(s)
  dim_customer.customer_id -> fct_seat_review.customer_id (1:N)

FROM dim_customer
JOIN fct_seat_review ON fct_seat_review.customer_id = dim_customer.customer_id
```

Positions live in `erd/qdbd.layout.json`. `qdbd layout --by-group erd` rewrites them with one region per file; qdbd labels each region with the file's path under `erd/`, such as `lounge_reviews/lounge_reviews`.

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
| `main` | (production) | [`/`](https://markphamm.github.io/qdbd-dbt-demo/) |
| `qa` | `dim_cabin`, a conformed dimension, with `cabin_id` on the airline and seat facts | [`/qa/`](https://markphamm.github.io/qdbd-dbt-demo/qa/), coloured against `main` |
| `dev` | `dim_route` built as a model, with `route_id` on `fct_airline_review` | [`/dev/`](https://markphamm.github.io/qdbd-dbt-demo/dev/), coloured against `qa` |

On `qa` or `dev`:

```bash
qdbd diff --base main erd
qdbd build erd --diff-base main -o /tmp/erd-diff.html
```

## CI/CD

Three workflows, no secrets. Everything they need is in this repo.

```mermaid
flowchart LR
    feature["feature branch"] -->|"PR · ci.yml"| dev["dev"]
    dev -->|"PR · ci.yml"| qa["qa"]
    qa -->|"PR · ci.yml"| main["main = prod"]

    dev -->|"push · cd.yml"| cd["dbt build<br/>--target dev / qa / prod"]
    qa -->|"push · cd.yml"| cd
    main -->|"push · cd.yml"| cd

    cd -->|"green · pages.yml"| pages["GitHub Pages<br/>/dev/ · /qa/ · /"]
```

Every pull request runs two jobs that share nothing:

- `slim-ci` asks whether the data still builds. It downloads the base branch's last green `cd.yml` artifacts and builds the models the pull request changed, plus everything downstream of them, deferring the rest.
- `erd` asks whether the diagram still matches the yml. It runs `qdbd check --strict erd`, posts one comment with the schema diff, and uploads the diagram as an artifact. It needs no dbt, no database and no earlier run.

| Workflow | Runs on | Does | Needs |
|---|---|---|---|
| `cd.yml` | push to `dev`, `qa`, `main` | `dbt build` on that branch's target (`main` builds `prod`), then uploads `manifest.json` + `database.duckdb` as the `dbt-artifacts` artifact | nothing |
| `ci.yml` › `slim-ci` | pull request into `dev`, `qa`, `main` | downloads `dbt-artifacts` from the **base branch's** last green `cd.yml`, then `dbt build --target ci --select state:modified+ --defer` | a green `cd.yml` on the base branch |
| `ci.yml` › `erd` | same pull request | `qdbd check --strict erd`, one comment with what the pull request changes in the diagram, the diagram as the `erd` artifact | nothing, not even dbt |
| `pages.yml` | after a green `cd.yml`, or Run workflow | checks out all three branches, builds `erd/` on each (`qa` with `--diff-base main`, `dev` with `--diff-base qa`), deploys to GitHub Pages | Pages turned on |

[![The qdbd comment on the qa → main pull request: 1 table added, 2 changed, 2 relationships added](docs/images/qdbd-pr-comment.png)](https://github.com/MarkPhamm/qdbd-dbt-demo/pull/2)

*The `erd` job's one comment on the real [`qa → main` pull request](https://github.com/MarkPhamm/qdbd-dbt-demo/pull/2). It is updated on every push.*

### Set it up

These are the steps this repo took, in order. They work the same in a copy of it.

1. **Put the files in place.** You need:
   - the three files in `.github/workflows/`
   - the `dev`, `qa`, `ci` and `prod` targets in `profiles.yml`
   - `macros/generate_schema_name.sql`
   - `erd/` with one `# @dbt:` line pointing at the folder that holds `dbt_project.yml`

   Keep `quickdbd-cli==0.6.0` in `pages.yml` and `MarkPhamm/quickdbd-cli@v0.6.0` in `ci.yml` on the same version.

2. **Check locally before pushing:**

   ```bash
   uv run dbt deps && uv run dbt build
   qdbd check --strict erd
   ```

3. **Push the branches in promotion order**, so each one runs `cd.yml` once and has artifacts before a pull request asks for them:

   ```bash
   git push origin main
   git push -u origin qa      # branched from main
   git push -u origin dev     # branched from qa
   gh run list --workflow cd.yml   # wait for three green runs
   ```

4. **Turn on Pages**, once, with the source set to GitHub Actions:

   ```bash
   gh api -X POST repos/<owner>/<repo>/pages -f build_type=workflow
   gh workflow run pages.yml
   ```

   Or use **Settings → Pages → Source → GitHub Actions**. Until then, `pages.yml` builds the sites and its `deploy` job fails with `Ensure GitHub Pages has been enabled`.

5. **Open the promotion pull requests:** `dev → qa` and `qa → main`. Each one gets a green `slim-ci`, a green `erd`, and a qdbd comment listing the tables, columns and relationships it adds or removes.

6. **Optional:** in **Settings → Branches**, protect `dev`, `qa` and `main`, and require the `slim-ci` and `erd` checks.

### Day to day

1. Branch from `dev`. Change a model and its yml. Update its file under `erd/` in the same commit.
2. Run `qdbd check --strict erd`. It fails if the diagram and the yml disagree, and so does CI.
3. Open a pull request into `dev`. Read the qdbd comment. Merge.
4. `cd.yml` rebuilds `dev`, and `pages.yml` republishes `/dev/`, coloured against `qa`.
5. Promote with a pull request `dev → qa`, then `qa → main`. Each merge rebuilds that environment and its page.

A fix made straight on `main` goes back down with a merge, not a rebase, so open pull requests keep their diffs:

```bash
git checkout qa && git merge main && git push
git checkout dev && git merge qa && git push
```

### Why it is built this way

- **Slim CI defers to the base branch, not to prod.** A pull request into `qa` is checked against what `qa` already has. `cd.yml` uploads under the same artifact name on every branch, and `ci.yml` picks the right one with `gh run list --branch <base>`.
- **`erd` shares nothing with `slim-ci`.** The yml link needs no build, so the diagram check stays green and fast even when no `cd.yml` has run yet.
- **`pages.yml` runs after `cd.yml`, not on push.** A `workflow_run` job runs on the default branch, and the `github-pages` environment only accepts deploys from the default branch. Every deploy rebuilds all three sites, so a push to `dev` never wipes `/qa/`.
- **One DuckDB file per run.** CI downloads the base branch's `database.duckdb` and writes into its own `ci_pr_<n>` schema in that copy. Nothing it does reaches an environment.

### On a real warehouse

Only the dbt half changes; the qdbd half stays as it is.

- `profiles.yml`: point each target at the warehouse, with `env_var("DBT_PASSWORD")` and the like, and store the values as GitHub secrets.
- `cd.yml`: upload only `manifest.json`. The warehouse already holds the data.
- `ci.yml`: drop the `database.duckdb` copy. `--defer --state` then reads the deferred relations from the base environment's schemas.
- Give CI credentials that cannot write to `prod`.

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

This repo is also the [Skytrax demo on qdbd.dev](https://qdbd.dev/demo/skytrax/#t=dim_customer).
