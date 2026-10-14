# astro-boilerplate — implementation plan

Milestones land in order; each task is one pull request on an
`orun/AB-n-<slug>` branch with an `Orun-Task: AB-n` trailer.

## AB0 — the spec

This doc set, `epic.yaml` and the task contracts, merged to `main`.

**Done when**
- the five documents and `epic.yaml` are on `main`
- `tasks/AB-1..AB-3.TaskContract.yaml` exist

## AB1 — the site on Workers

`apps/web` is the upstream boilerplate with the Cloudflare adapter, the
beacon in the layout, and container-API tests.

**Done when**
- `pnpm install && pnpm typecheck && pnpm lint && pnpm test && pnpm build` is green locally and in `Checks`
- `wrangler dev` answers `/` (200, "Welcome to Astro"), `/ssr` and `/ssr-with-swr-caching` (200, a time; the latter with the Cache-Control header), `/image` (200 with an `<img>` whose `src` answers 200 with an image), `/nope` (404)

## AB2 — ready to instantiate

README (run, test, preview, deploy; the beacon token; the SWR note),
`IMPLEMENTATION-STATUS.md`, epic `completed`.

**Done when**
- the README quick start works from a fresh clone
- the status file lists every PR and departure

## Sequencing note

AB1 needs only AB0's contracts; AB2 is documentation over AB1's verified
build. Deploying is the gated Orun lane, not a milestone.
