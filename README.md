# qdbd-dbt-demo

A small dbt project on DuckDB, built so [qdbd](https://qdbd.dev/) has something real to draw: descriptions that live in dbt yml, a schema diff between git branches, and the same dev / ci / prod targets as [dbt_duckdb_cicd_template](https://github.com/MarkPhamm/dbt_duckdb_cicd_template). That repository is the course. This one is the diagram.

```
raw_customers ──> stg_customers ──────────────────────────> customers
raw_orders ─────> stg_orders ─────────────────────────────> orders
raw_payments ───> stg_payments ──> int_order_payments ────> orders
```

`planned_refunds` is on the hand-written diagram only. It is not a dbt model.

## Setup

Python 3.12 and [uv](https://docs.astral.sh/uv/). qdbd 0.6.0, the same pin as CI:

```bash
uv sync
uv tool install "quickdbd-cli==0.6.0"
uv run dbt build
```

`profiles.yml` is committed because DuckDB has no credentials. dbt reads it from the project directory.

## Two diagrams

| Path | What it is |
|---|---|
| `schema/schema.txt` | Hand-written. `# @dbt: ..` fills descriptions, tags and column types from the yml and from `models/docs.md`. No `manifest.json`. |
| `erd/generated/` | Written by `qdbd import dbt` after `dbt docs generate`. Columns and types come from the manifest and the catalog. Relationships are the `relationships` tests. |

Pass one of those paths to qdbd. The repo root contains both, and qdbd would merge them into one namespace and report duplicate tables.

`raw_`, `stg_` and `int_` take their header colour from the name. `customers` and `orders` are tagged `mart` in the yml, and `schema/schema.txt` sets that colour with `# @color mart`.

`# @dbt: none` above `planned_refunds` tells qdbd the table is not in dbt, so `qdbd check` stays quiet about it.

## dbt targets

One `database/database.duckdb`. The target chooses the schema.

| Target | Schema |
|---|---|
| `dev` (default) | `dev`, everything flat |
| `ci` | `ci_local`, or `ci_pr_<n>` when `DBT_CI_SCHEMA` is set |
| `prod` | `raw`, `staging`, `intermediate`, `marts` |

`macros/generate_schema_name.sql` is what makes prod split and the other two stay flat. dbt's built-in macro would concatenate instead (`dev_staging`).

```bash
uv run dbt build --target dev
uv run dbt build --target ci
uv run dbt build --target prod
```

The diagram does not change with the target. It describes the code, not the schema the rows land in.

## Git branches

| Branch | Schema |
|---|---|
| `main` | Matches the yml. `qdbd check --strict schema` is clean. |
| `qa` | Adds `orders.shipped_at` (SQL, yml and both diagrams) and a `relationships` test from `stg_payments.order_id` to `stg_orders.order_id`. Open as a pull request into `main`. |
| `dev` | The `qa` change, plus `orders.internal_note` in `schema/schema.txt` only. `qdbd check schema` warns. This branch has no pull request, so CI does not run it. |

On `qa` or `dev`:

```bash
qdbd diff --base main schema
qdbd diff --base main erd/generated
qdbd build schema --diff-base main -o /tmp/schema-diff.html
qdbd build erd/generated --diff-base main -o /tmp/generated-diff.html
```

Run the two diffs separately. One command with both paths would compile them together.

## qdbd commands

```bash
qdbd check schema
qdbd check --strict schema
qdbd serve schema
qdbd build schema -o /tmp/schema.html
qdbd build erd/generated -o /tmp/generated.html
qdbd path schema --from raw_customers --to orders
qdbd build erd/generated -s group:marts -o /tmp/marts.html
```

`qdbd serve schema` and then open `orders`. The description on the table comes from `models/marts/schema.yml`. The description on `payment_method` comes from the `{% docs payment_method %}` block in `models/docs.md`.

Regenerate the import after a model change, then commit `erd/generated/`:

```bash
./scripts/build-erd.sh
```

Positions live in `schema/qdbd.layout.json` and `erd/generated/qdbd.layout.json`. `qdbd layout schema` and `qdbd layout erd/generated` rewrite them.

## CI

`cd.yml` runs on a push to `main`: `dbt build --target prod`, then uploads `manifest.json`, `catalog.json` and `database.duckdb`.

`ci.yml` runs on a pull request:

- `slim-ci` downloads that artifact and runs `dbt build --target ci --select state:modified+ --defer`. The first pull request needs a green `cd.yml` on `main` before this job can download anything.
- `erd` builds the project, fails if `erd/generated/` is stale, and posts one comment with the schema diff. The diagram artifact is named `erd`.

## Elsewhere in qdbd

This repo does not set these up. The docs do:

- [MCP](https://qdbd.dev/mcp/) for agents
- [Sharing a gist](https://qdbd.dev/sharing/)
- [DBML](https://qdbd.dev/dbml/)
- [PNG, SVG and draw.io](https://qdbd.dev/exports/)
- [VS Code](https://qdbd.dev/vscode/)
