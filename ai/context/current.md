# astro-boilerplate — where this repository stands

The entry page for anyone (or any agent) picking this repository up. It is
this repository's own state and does not ship to a site built from it; the
two pages that do are [operations.md](operations.md) and
[deployment.md](deployment.md).

## What it is

Vercel's Astro boilerplate — a pre-rendered home page, two server-rendered
pages (one setting stale-while-revalidate cache headers) and an
optimised-image page — run on Cloudflare Workers + Static Assets through
Astro's own Cloudflare adapter, packaged as an Orun baseline: `orun new
--blueprint repo-blueprint.yaml` builds a new site in its own repository and
takes it to live on stage and prod in one landing (`01-product`), then
records what went live (`03-docs`).

## Release

| | |
|---|---|
| Latest tag | `baseline-v1` (AB3: three phases, `01-scaffold`, `02-site`, `03-docs`) |
| On `main` since | AB4 — one landing ([#5](https://github.com/sourceplane/astro-boilerplate/pull/5), AB-5); AB5 — the cirrus standard (no kiox, generated component docs, this context pack) |
| Proven live | `baseline-v1`: yes — a console bootstrap went live on stage and prod on 2026-10-15 (`astro-live`, `bst_XYM9M4ZT`, 7m07s). `main`'s one-landing shape: no — proven offline in Baseline CI only, and no tag carries it yet (risk AB-G) |

## Where to read

| Question | Page |
|---|---|
| What shipped, and every departure from upstream | `specs/epics/astro-boilerplate/IMPLEMENTATION-STATUS.md` |
| Why it is built this way | [decisions.md](decisions.md), then `specs/epics/astro-boilerplate/design.md` |
| What could still go wrong | [open-risks.md](open-risks.md), then `specs/epics/astro-boilerplate/risks-and-open-questions.md` |
| How to instantiate it | `BOOTSTRAP.md`, `docs/phases/` |
| What the component is | `apps/web/docs/` (generated; `python3 tooling/catalog/gen-component-docs.py`) |

## Next

1. Cut the next `baseline-vN` with `tag.yml`, so a tag carries AB4 and AB5.
2. Bootstrap one site from it from the console, and record its timings
   against the 5-minute estimate and baseline-v1's 7m07s (closes AB-G and
   AB4's last exit criterion).
