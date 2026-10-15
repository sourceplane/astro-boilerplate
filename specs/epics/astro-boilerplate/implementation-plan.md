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

## AB3 — a baseline

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

## After AB3 (outside this repository)

1. Cut `baseline-v1` with `tag.yml` from the merged `main`.
2. Register the row in orun-cloud's `infra/baselines-registry/baselines.yaml`
   (unlisted) with the card vendored at the tag.
3. Bootstrap one site from the tag against a workspace; record its timings;
   then flip the row to public with a page on orunbase.com.

## Sequencing note

AB1 needs only AB0's contracts; AB2 is documentation over AB1's verified
build; AB3 packages AB1's site as a baseline. Deploying is the gated Orun
lane, not a milestone.
