#!/usr/bin/env bash
# Regenerate erd/generated/ from the dbt project.
#
# schema/schema.txt is hand-written and linked to the yml with `# @dbt:`.
# This script does not touch it.
#
# Run this whenever you add, remove or rename a model, a seed or a column,
# then commit erd/generated/ with the rest of the change. CI runs the same
# import with --check and fails the pull request if what you committed is
# out of date.
#
# The version is pinned to match .github/workflows/ci.yml. Bump both together,
# or local and CI will disagree about what "up to date" means.
set -euo pipefail

QDBD_VERSION="0.6.0"

cd "$(dirname "$0")/.."

# Two files come out of this, and the import needs both:
#   target/manifest.json  every table, every documented column, every test
#   target/catalog.json   the column types, read back out of the warehouse
# dbt can only write the catalog for relations that exist, which is why this
# builds first.
#
# No --target: the ERD is the same for dev, ci and prod. The target only
# decides which schema the relations land in.
uv run dbt build
uv run dbt docs generate

# qdbd finds target/catalog.json because it sits next to the manifest.
uvx --from "quickdbd-cli==${QDBD_VERSION}" qdbd import dbt target/manifest.json -o erd/generated

echo
echo "erd/generated/ regenerated. Commit it:  git add erd/generated && git commit"
