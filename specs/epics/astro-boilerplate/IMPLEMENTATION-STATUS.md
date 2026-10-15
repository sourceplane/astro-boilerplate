# astro-boilerplate (AB) — Implementation status

As-built ≠ intent. This file records what actually shipped, and every place
the code departed from `design.md` or from the upstream template.

| Milestone | State | PR |
|---|---|---|
| AB0 — the spec | ✅ Shipped | [#1](https://github.com/sourceplane/astro-boilerplate/pull/1) |
| AB1 — the site on Workers | ✅ Shipped | [#2](https://github.com/sourceplane/astro-boilerplate/pull/2) |
| AB2 — ready to instantiate | ✅ Shipped | [#3](https://github.com/sourceplane/astro-boilerplate/pull/3) |
| AB3 — a baseline | 🟡 In progress | this PR (AB-4) |

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
