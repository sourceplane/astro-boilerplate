# astro-boilerplate — implementation plan

Milestones land in order; each task is one pull request on an
`orun/AB-n-<slug>` branch with an `Orun-Task: AB-n` trailer.

## AB0 — the spec ✅

This doc set, `epic.yaml` and the task contracts, merged to `main`.

**Done when**
- the five documents and `epic.yaml` are on `main`
- `tasks/AB-1..AB-3.TaskContract.yaml` exist (AB-4 joined with AB3)

## AB1 — the site on Workers ✅

`apps/web` is the upstream boilerplate with the Cloudflare adapter, the
beacon in the layout, and container-API tests.

**Done when**
- `pnpm install && pnpm typecheck && pnpm lint && pnpm test && pnpm build` is green locally and in `Checks`
- `wrangler dev` answers `/` (200, "Welcome to Astro"), `/ssr` and `/ssr-with-swr-caching` (200, a time; the latter with the Cache-Control header), `/image` (200 with an `<img>` whose `src` answers 200 with an image), `/nope` (404)

## AB2 — ready to instantiate ✅

README (run, test, preview, deploy; the beacon token; the SWR note),
`IMPLEMENTATION-STATUS.md`, epic `completed`.

**Done when**
- the README quick start works from a fresh clone
- the status file lists every PR and departure

## AB3 — a baseline (AB-4) ✅

`blueprint.yaml`, `repo-blueprint.yaml`, `.baseline/` (identity, task
contracts, the site's README), `tooling/rebrand`, `tooling/bootstrap`,
`hooks/render-deployment-docs.sh`, `ai/context/`, `docs/phases/`,
`BOOTSTRAP.md`, `testing/`, `baseline.yml` and `tag.yml`; the `SITE_NAME`
seam and the committed deploy config in `apps/web` (design §6).

**Done when**
- orun at the bootstrap floor (v2.58.11) and at the lane pin (v2.78.4) reads
  `repo-blueprint.yaml`, and `testing/manifest.test.sh` holds the card to it
- `Baseline CI` is green: the contract tests, the leak gate, the offline
  bootstrap (`testing/placement.test.sh`) and the end-to-end tier
  (`testing/e2e.test.sh`), whose stage lane runs in a staged job tree from
  the install through the dry deploy
- the status file records what is proven offline and what only a live
  bootstrap can prove

## AB4 — one landing (AB-5) ✅

The site in one landing, the way cirrus-baseline's baseline-v22 builds its
product: `repo-blueprint.yaml` places every module in `01-product` and
records it in `03-docs` (hooks only); the card's programme names the same
two; each bootstrap pull request is checked by `plan` alone (`ci.yml` skips
the lanes and `checks.yml` its job on `orun/BASE-…` branches); the brokered
secrets are minted in `01-product`'s `post`, after `repo` and `link`.

**Done when**
- `testing/phases.test.sh` holds the two phases and their hooks, and the
  offline bootstrap and the e2e tier pass over one landing
- Baseline CI is green
- a site bootstrapped from the next tag is live faster than baseline-v1's
  measured 7m07s — not yet: `baseline-v2` carries AB4 but has not been
  bootstrapped live (risk AB-G)

## AB5 — the cirrus standard (AB-6) ✅

Bring the baseline to cirrus-baseline's standard, with nothing about the
site itself changing.

- **No kiox.** `kiox.yaml`/`kiox.lock` pinned an orun (v2.15.0) that nothing
  ran: every workflow installs orun itself through `orun-action` with its own
  `version:`. The files, their two modules, the rebrand's skip entry and the
  01-product phase document's mention go.
- **Component docs.** `tooling/catalog/gen-component-docs.py` writes the
  component's `docs/overview.md`, `docs/architecture.md` and
  `docs/runbook.md` from what it declares, as cirrus-baseline's do; the pages
  ship with the component. Baseline CI runs it with `--check`.
- **The context pack.** `ai/context/current.md`, `decisions.md` and
  `open-risks.md` beside the two pages a site ships with — this
  repository's own, so no module places them.
- **Status that agrees with the tags and the live record.** AB4 is shipped
  and `baseline-v2` tags it with AB5; `baseline-v1` went live on 2026-10-15,
  so risk AB-G is now about the one-landing shape.
- **The subdomain from the Cloudflare connection (AB-7).** The card declares
  `subdomain` as `from: connection.cloudflare.workersSubdomain`, as
  cirrus-baseline does since baseline-v23, so the console asks for nothing the
  connection already knows; `testing/manifest.test.sh` requires the source's
  provider in `spec.requires.integrations`.

**Done when**
- nothing outside this milestone's own record (its specs, task and context
  pages) names kiox, and the leak gate and the offline bootstrap pass
  without the two modules
- the docs check is green in Baseline CI
- the card renders no subdomain field, and the manifest gate fails a
  `connection.` source whose provider the card does not require
- this file, the status file and `epic.yaml` agree

## AB6 — the domain is set later (AB-8) ✅

**Done when** the console card asks for no domain; `productdomain` is an
optional build input, empty by default; a site built without one is branded
with the reserved placeholder `<reponame>.example.com` where the domain goes
(`BASE_DOMAIN` in `intent.yaml`, the README's `SITE_URL` example) and its
README says how an owner sets the real one; Baseline CI places, leak-checks
and plans a site built with no domain. Shipped in `baseline-v3`.

## After AB3 (outside this repository)

1. Cut `baseline-v1` with `tag.yml` from the merged `main` — done.
2. Register the row in orun-cloud's `infra/baselines-registry/baselines.yaml`
   (unlisted) with the card vendored at the tag.
3. Bootstrap one site from the tag against a workspace; record its timings;
   then flip the row to public with a page on orunbase.com. — The bootstrap
   ran on 2026-10-15 (7m07s, live on stage and prod; IMPLEMENTATION-STATUS).

## Sequencing note

AB1 needs only AB0's contracts; AB2 is documentation over AB1's verified
build; AB3 packages AB1's site as a baseline. Deploying is the gated Orun
lane, not a milestone.
