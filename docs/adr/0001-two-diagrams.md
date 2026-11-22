# Two diagrams, and dbt workflows kept apart from qdbd workflows

The reference project publishes a model diagram and a source diagram, and its CI names say which tool each job runs. Accepted because the learning sandbox already showed the qdbd half, and copying it into one unnamed `ci.yml` hid which check was dbt and which was qdbd.

## Considered options

- Leave both diagrams in one `qdbd check erd`. A glob of `erd/*/` splits the star schemas, and the facts can no longer see `dim_customer`.
- Keep `ci.yml` and `cd.yml` as the dbt jobs and add qdbd beside them under those names. The Actions list then has two "ci" workflows that do different work.
- Build the Pages diagrams with `qdbd build --site`. That replaces `index.html` with a link page and breaks the model-diagram URL.

## Decision

`erd/models/` stays one schema. `erd/sources/` is a second schema. Checks pass both roots to `qdbd check --each`. Pages writes the model diagram to `index.html` and the source diagram to `sources.html`, both with `qdbd build --by-group`.

dbt and qdbd each get feature and release workflows: `feature-ci-dbt`, `feature-ci-qdbd`, `feature-cd-qdbd`, `release-ci-dbt`, `release-ci-qdbd`, `feature-cd-dbt`, `release-cd-dbt`, and `release-cd-qdbd`. `pages` rebuilds every environment and every open pull request after a qdbd preview or a dbt CD.

## Consequences

A pull request into `dev` or `qa` runs three jobs, and a pull request into `main` runs two. `/sources.html` and `/pr/N/` appear when `pages.yml` reaches `main`. Until then, a deploy from the previous `pages.yml` draws a branch's model and source tables on one page, because `qdbd build erd` compiles every file under `erd/`. The qdbd.dev link to the model diagram stays the same URL.
