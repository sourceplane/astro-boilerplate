# astro-boilerplate (AB) — Implementation status

As-built ≠ intent. This file records what actually shipped, and every place
the code departed from `design.md` or from the upstream template.

| Milestone | State | PR |
|---|---|---|
| AB0 — the spec | ✅ Shipped | [#1](https://github.com/sourceplane/astro-boilerplate/pull/1) |
| AB1 — the site on Workers | ✅ Shipped | [#2](https://github.com/sourceplane/astro-boilerplate/pull/2) |
| AB2 — ready to instantiate | ✅ Shipped | [#3](https://github.com/sourceplane/astro-boilerplate/pull/3) |
| AB3 — a baseline | ✅ Shipped | [#4](https://github.com/sourceplane/astro-boilerplate/pull/4) (AB-4), tagged `baseline-v1` |
| AB4 — one landing | ✅ Shipped | [#5](https://github.com/sourceplane/astro-boilerplate/pull/5) (AB-5) — on `main`, not yet tagged (the next tag ships it); not yet proven live (risk AB-G) |
| AB5 — the cirrus standard | ✅ Shipped | AB-6 — on `main` after AB4, not yet tagged |

## Departures from the upstream template

### `@astrojs/cloudflare` for `@astrojs/vercel`

`astro.config.ts`: `adapter: cloudflare({ imageService: 'compile' })`. The
Vercel adapter's `webAnalytics` becomes the Cloudflare beacon in
`Layout.astro`, opt-in by `PUBLIC_CF_BEACON_TOKEN`.

### Astro 7, adapter 14

The template floats `^5.1`; the current adapter needs ≥ 7.2.

### `session: false`

The adapter would otherwise enable KV sessions and require a `SESSION`
namespace; the template has no sessions.

### The unused `react` dependency is dropped

The template lists `react 18.3.1` without a React integration; nothing
imports it.

### The home page's name comes from `src/site.ts` (AB3)

`SITE_NAME` replaces the literal "Astro" in the home page's `<title>`
("Welcome to Astro."), its heading ("Welcome to *Astro*") and the Code
Challenge line under it. It is the seam the baseline's rename rewrites; the
framework's own name elsewhere (the link cards, the logo's alt text) is
content and stays. The boilerplate shows no source link, so there is no
`SOURCE_URL`.

### `apps/web/README.md` is the app's, not the template's (AB3)

The upstream README advertised "Deploy with Vercel" and a Vercel demo, and it
ships into every site. It now describes the app and credits the template
(MIT).

## Departures from the port (AB3)

| What | Before | After | Why |
|---|---|---|---|
| `apps/web` `wranglerConfig` | `dist/server/wrangler.json` (the adapter's generated config) | the committed `wrangler.deploy.jsonc`, the same settings pointed at the built Worker | the lane runs `test -f <wranglerConfig>` before `build-app`, in a job tree staged without `dist/`: every lane would have failed there (risks AB-I) |
| `apps/web` `preview` | `wrangler dev --config dist/server/wrangler.json` | `--config wrangler.deploy.jsonc` | preview serves what deploys |
| `apps/web` tests | the link card and the layout | + the site-name seam on the rendered home page; + `wrangler.deploy.jsonc` says everything `wrangler.jsonc` says | an owner who adds a binding to one file and not the other is told by `pnpm test` |
| `apps/web` smoke | `grep 'Welcome to'` on `/` | the same, and `/ssr` renders an `<h1>` | `/` is pre-rendered and answers from the assets even when the Worker does not |
| `ci.yml` gate | `vars.ORUN_CI == 'true'` | skip only while `intent.yaml` names `ws_CHANGE_ME` | a bootstrap cannot set a repository variable |
| `checks.yml` | push and pull request | pull request and `workflow_dispatch` | a push to main must start `ci.yml` alone: the bootstrap's watch takes the newest run for the commit from any workflow (risks AB-K) |
| stack-tectonic | 0.18.2 | 0.19.0 | first-deploy retry; NOT 0.20.0, whose lane-scoped install links each job's `node_modules` out of its tree (risks AB-J) |
| orun lane pin | v2.78.0 | v2.78.4 | the sibling baselines' pin |
| `intent.yaml` | terraform `parameterDefaults`; docs pages under `specs/` | neither; docs pages `ai/context/*` | no terraform component; the pages must exist in a site |
| discovery roots | `apps/` only on disk | `infra/`, `packages/`, `tests/` carry a `.gitkeep` | `orun validate` and `orun plan` refuse a missing root |
| `tasks/AB-1..3` | no `metadata` | `metadata.name` and `title` | `orun work check` (≥ v2.79) refuses a contract without them |

## One landing (AB4)

cirrus-baseline's baseline-v22 builds its whole product in one landing
(`01-product`) and checks each bootstrap pull request with `plan` alone. This
baseline now does the same (AB-5):

| Before (baseline-v1) | Now | Why |
|---|---|---|
| three phases: `01-scaffold`, `02-site`, `03-docs` | two: `01-product` (every module), `03-docs` (hooks only; its name kept, the gap kept, as Cirrus kept `08-docs`) | a landing has a fixed cost (place, PR, checks, merge, convergence start); nothing in the scaffold/site split was order the plan could not carry |
| `01-scaffold` waited on Checks (install, typecheck, lint, test, build) and `plan`; `02-site` merged without waiting (`wait: false`); `03-docs` waited on both | every landing waits on its PR's CI, which on `orun/BASE-…` is `plan` alone: `ci.yml` skips the lanes and `checks.yml` now skips its job | the convergence on main installs, builds, deploys and smoke-tests the site for real; Checks on the PR was the same build twice, and most of each landing's wait. Its typecheck, lint and tests run over a bootstrapped copy of the same tree in Baseline CI's e2e tier, before a tag is cut |
| the brokered secrets minted in `02-site`'s `pre` | minted in `01-product`'s `post`, after `repo` and `link`, before `land` | the repository exists and is linked before a secret is written for its project — Cirrus's order |
| `02-site` seeded the lockfile from the baseline's, then pruned | `pnpm install --lockfile-only` only confirms the placed lockfile | the whole tree is placed at once, so the complete lockfile is already the right one |
| `.baseline/tasks/01-scaffold`, `02-site` | `.baseline/tasks/01-product` (`affects: [web]` — the retouch set) | one landing, one task |
| the offline bootstrap committed one landing per phase from an empty repository | the repository's empty first commit, then one per phase | on the platform the first pull request opens against an empty "Initial commit" by `orun`; it is the base the one landing's push is planned against (`testing/placement.test.sh` §4, `testing/e2e.test.sh` §2) |
| e2e ran the Checks at the scaffold's landing and at the finished site | at the finished site only | there is no scaffold landing, and no landing waits on Checks |

Measured on `baseline-v1` from the console's Build, 2026-10-15
(`astro-live`, `bst_XYM9M4ZT`): 7m07s end to end — about 1m28s of build
sandbox start, `01-scaffold` 1m4s, `02-site` 3m19s, `03-docs` 1m16s (its
landing waited about 33s on Checks) — and the site went live on stage and
prod. The estimate here is 5 minutes (4 + 1), to be replaced by the first
bootstrap from `baseline-v2`.

## The cirrus standard (AB5)

Nothing about the site changed. What changed is the baseline around it:

| What | Before | After | Why |
|---|---|---|---|
| orun pin | `kiox.yaml` (v2.15.0) + `kiox.lock`, shipped to every site; "the kiox pin" in `docs/phases/01-product.md` | gone; orun is pinned where it runs, the `orun-action` `version:` in each workflow | nothing ran the kiox pin, and it disagreed with the lanes (v2.78.4) |
| `root-kiox`, `root-kiox-lock` modules | in `01-product` | removed (`testing/phases.test.sh` and the rebrand's skip list follow) | a site is placed with 54 files: 53 − 2 kiox + 3 docs pages |
| component docs | none | `apps/web/docs/` — `overview.md`, `architecture.md`, `runbook.md` | cirrus-baseline documents every component; the workspace Docs library renders `docs/` beside each `component.yaml` |
| how the docs stay true | — | `tooling/catalog/gen-component-docs.py` derives them from the manifest, the Worker config and package scripts; Baseline CI runs it with `--check` | a hand-written copy of a manifest drifts silently |
| context pack | `operations.md`, `deployment.md` | plus `current.md`, `decisions.md`, `open-risks.md` | cirrus-baseline's shape; the three new pages are this repository's own and no module places them (the leak gate still allows exactly two) |
| status | AB4 "in progress / this PR"; AB-G "no live bootstrap yet", citing the removed `02-site`; `design.md` naming "the scaffold" as what writes the workspace | AB4 shipped, untagged — the next tag ships it; AB-G: `baseline-v1` went live (2026-10-15), the one-landing shape is not yet proven live — still OPEN; `01-product` writes the workspace | the merge and the live run had happened; the documents had not caught up |

## Verified (AB5)

- `testing/{manifest,phases,coverage,rebrand,retouch,bootstrap-defer}.test.sh`
  green; `gen-component-docs.py --check` green (1 component, 3 pages).
- `orun new --status` (v2.58.11, the bootstrap floor): `01-product` 54
  files, `03-docs` hook-only.
- `testing/leak.test.sh` (v2.58.11): 54 files derived (53 − 2 kiox + 3 docs
  pages); ai/context still exactly the two declared pages.
- `testing/placement.test.sh` (v2.58.11, as Baseline CI runs it): 54 files
  placed, both landings (`01-product`, `03-docs`), branded, re-tenanted,
  record rendered; the site's own plan for the 01-product merge deploys
  `web` to stage and prod side by side; `--resume` changes nothing.
- `pnpm install --frozen-lockfile`, `wire:fixture`, `typecheck` (0 errors),
  `lint` (`astro check`, 0 errors, 0 warnings), `test` (6 tests), `build`
  green.
- `testing/e2e.test.sh` (v2.78.4): the offline bootstrap places and lands
  both phases; the finished site passes the Checks sequence; the stage
  lane's `install-workspace-dependencies`, `verify-app-structure`,
  `build-app`, `verify-build-output` and `deploy-dry-run` pass in the staged
  job tree, and the committed deploy config uploads what the adapter's
  generated one would; under `wrangler dev` the component's own smoke
  passes, and `/`, `/ssr`, `/ssr-with-swr-caching`, `/image` and its image,
  `/favicon.ico` and a 404 are the site's own (the new `docs/` pages are not
  site content).
- `orun task check AB-6` complete.

## Verified (AB3)

- `orun new --status` reads the blueprint at v2.58.11 (the bootstrap floor),
  v2.78.4 (the lane pin) and v2.79.0; `orun validate` passes on this tree.
- `testing/{manifest,phases,coverage,rebrand,retouch,bootstrap-defer}.test.sh`
  green; `orun work check` clean.
- `testing/leak.test.sh`: 53 files derived; nothing of the factory, nothing
  local or built; no provenance prose.
- `testing/placement.test.sh` (offline bootstrap, fixture "Sam's Stars &
  Notes" / `acme-inc/acme-astro-site`): three landings; rebrand `--verify`
  clean; no file of the site names a factory path; workspace re-tenanted,
  `work:` stripped, promotion and dev lanes restored; deployment record
  rendered; the site's own `orun plan` for the 02-site merge deploys `web` to
  stage and prod side by side with the site's Worker name, deploy config,
  smoke and secret refs; `--resume` changes nothing.
- `testing/e2e.test.sh`: the scaffold's landing and the finished site pass
  the Checks sequence; in a job tree staged as orun stages it, the stage
  lane's `install-workspace-dependencies`, `verify-app-structure`,
  `build-app`, `verify-build-output` and `deploy-dry-run` pass, and a dry run
  of `wrangler.deploy.jsonc` uploads exactly what the adapter's
  `dist/server/wrangler.json` would (19 modules, 6 assets, the `ASSETS`
  binding); `wrangler dev` serves the built Worker; the component's own smoke
  passes; `/` (heading and title carry the escaped name), `/ssr` (a new time
  per request), `/ssr-with-swr-caching` (with its `Cache-Control`), `/image`
  and its image, `/favicon.ico` and a 404 are the site's own.
- The same tier with AB2's `wranglerConfig: dist/server/wrangler.json` fails
  at `verify-app-structure` — the defect it now guards.
- Astro's build in the lane-shared layout (stack-tectonic 0.20.0's symlinked
  `node_modules`) was tried once, by hand: it builds and dry-deploys. Not
  adopted (risks AB-J).
- Not verified: a live bootstrap against a workspace (risks AB-G).
- (Note, AB5: on 2026-10-15 a console bootstrap of `baseline-v1` went live
  on stage and prod in 7m07s — see "One landing (AB4)". AB4's one-landing
  shape is the part not yet proven live.)

## Verified (AB1–AB2)

- Local: `astro check` (0 errors), `pnpm test` (2 container-API tests),
  `pnpm build` green; `wrangler dev --config dist/server/wrangler.json`:
  `/` 200 ("Welcome to Astro"), `/ssr` 200, `/ssr-with-swr-caching` 200
  with `Cache-Control: s-maxage=10, stale-while-revalidate`, `/image` 200
  and its `<img>` src 200 `image/png`, `/nope` 404.
- CI: `Checks` green on #2.
- Not verified: a live deploy (gated until the product is linked to an Orun
  workspace with a Cloudflare connection); the beacon with a real token;
  Cloudflare caching of the SWR page (needs a Cache Rule).

## Versions

| Package | Version | Why |
|---|---|---|
| astro | ^7.3.8 | the current Cloudflare adapter needs ≥ 7.2; the template floats `^5.1` |
| @astrojs/cloudflare | ^14.3.4 | builds through the Cloudflare Vite plugin; emits dist/server + dist/client |
| wrangler | ^4.151.0 | compatibility_date 2026-10-01 |
