# astro-boilerplate — design

## 1. What the template is

Astro with `output: 'server'` and the Vercel adapter. `index.astro` is
pre-rendered (`export const prerender = true`) and shows four link cards;
`ssr.astro` renders the time per request; `ssr-with-swr-caching.astro` does
the same and sets `Cache-Control: s-maxage=10, stale-while-revalidate`;
`image.astro` renders `src/assets/logo.png` through `astro:assets` at width
50. The adapter enables Vercel's image service and web analytics.

## 2. The mapping (Vercel → Cloudflare)

| Vercel primitive the template uses | Here |
|---|---|
| `@astrojs/vercel` (serverless output) | `@astrojs/cloudflare` (through the Cloudflare Vite plugin): the Worker under `dist/server/` with a generated `dist/server/wrangler.json` (`no_bundle`, `main: entry.mjs`, `assets: ../client`), the static output under `dist/client/` with `.assetsignore` and `_headers` |
| `imageService: true` (Vercel's image optimisation) | `imageService: 'compile'`: images on pre-rendered pages are optimised at build time with sharp. `image.astro` is server-rendered (no `prerender`), so its `<Image>` resolves to the adapter's `/_image` passthrough endpoint and the original PNG is served at the requested size attributes |
| `webAnalytics` | The Cloudflare Web Analytics beacon in `Layout.astro`, rendered when `PUBLIC_CF_BEACON_TOKEN` is set at build time |
| `s-maxage` + `stale-while-revalidate` honoured by Vercel's CDN | The header is emitted unchanged. Cloudflare caches a Worker's dynamic response only when a Cache Rule (or the Cache API) says so; with a Cache Rule for the route, `s-maxage`/`stale-while-revalidate` are honoured. Without one the page renders per request |
| Deploy on push | Orun: `apps/web/component.yaml` (`cloudflare-workers-assets-turbo`) deploys `astro-boilerplate-web-{stage,prod}` on merge to `main` once the product is linked |

Alternative rejected: `output: 'static'` + assets only. It would drop the
two SSR pages, which are the point of the boilerplate.

## 3. The repository

```
apps/web               the boilerplate (src/, public/) + the Cloudflare adapter
  astro.config.ts      cloudflare adapter, compile-time images, sessions off
  wrangler.jsonc       worker name, compatibility date and flags, ASSETS binding (the
                       adapter derives dist/server/wrangler.json from it at build)
  component.yaml       build with turbo, deploy dist/server/wrangler.json, smoke /
  vitest.config.ts     Astro's Vite config (adapter left out) for the container-API tests
```

No `tests/` package: Astro components render only through Astro's Vite
plugin, so the tests live beside the app and `pnpm test` runs them there.

## 4. The build

`pnpm --filter @app/web build` = `astro build` → `dist/server/entry.mjs` +
`dist/server/wrangler.json` (the Worker and its deployable config),
`dist/client/index.html` (the pre-rendered page), `dist/client/_astro/*`
(hashed assets), `dist/client/_headers` (immutable caching for `/_astro/*`).
The Orun component deploys `dist/server/wrangler.json` with `--name
astro-boilerplate-web-<env>`. Locally, `pnpm --filter @app/web preview` runs
`wrangler dev` over the same config.

## 5. Out of scope

React islands (the template lists `react` but configures no integration;
the port drops the unused dependency), a custom-domain component (§6: the
brokered deploy token carries no zone permissions, so attaching a domain is
the owner's step), and Cache Rules for the SWR page (an account-level
setting).

## 6. The baseline (AB3)

The repository instantiates new sites the way
[cirrus-baseline](https://github.com/sourceplane/cirrus-baseline) instantiates
products, and the way its Next.js sibling `portfolio-starter-kit` instantiates
portfolios: a console card (`blueprint.yaml`) the platform renders, a build
document (`repo-blueprint.yaml`) `orun new` runs, and a rename engine that
makes the copy somebody else's.

| Cirrus | Here | Why the difference |
|---|---|---|
| `01-product` (the whole product in one landing), `07-domain`, `08-docs` (baseline-v22) | two: `01-product` (the whole site in one landing), `03-docs` (AB-5; three — `01-scaffold`, `02-site`, `03-docs` — before it) | one component deploys; no data plane, no fleet, no bindings, no domain phase |
| `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_D1_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` | `CLOUDFLARE_API_TOKEN` (`workers-deploy`), `CLOUDFLARE_ACCOUNT_ID` | no D1 |
| `07-domain` (parked component) | no domain phase; `SITE_URL` per environment, probed by the record | `workers-deploy` has no DNS or zone scope; the site builds no absolute links, so nothing needs the origin at build time |
| task contracts in `tasks/` | `.baseline/tasks/` | `tasks/` is this repository's own work tree (`intent.yaml` `work:`), where an unkeyed contract is an error |
| ships its own README | ships `.baseline/product/README.md` as the site's README | this README is about the baseline; a site's owner needs the site's |
| — | `work-tree.mjs` strips `work:` from the site's intent | a site has no `specs/` or `tasks/` |
| stack-tectonic 0.20.0 (lane-scoped install) | 0.19.0 (the job installs in its own tree) | the pin its Next.js sibling was proven to need; Astro's build was not tried live in the shared layout (risks AB-J) |
| one push workflow (`ci.yml`), no `checks.yml` | `checks.yml` on pull requests only, its job skipped on bootstrap branches (`orun/BASE-…`) | `orun.run/watch@v1` takes the newest run for a commit from any workflow (risks AB-K); a bootstrap landing is checked by `plan` alone, as Cirrus's is (AB-5) |
| a `tests/<worker>` package per worker | the app's tests in `apps/web/src/test`; no `tests/web` module | Astro components render only under Astro's Vite config (risks AB-D) |
| rebrand rules for a SaaS (console prefix, SDK class, CLI bin, API host) | rules for a site: a source link (owner + repo), the `SITE_NAME` seam, the domain, the subdomain, Worker names, secret refs, the repo slug | the identity this tree actually carries |

**Identity in the app** is one literal, `SITE_NAME` in `apps/web/src/site.ts`
(the home page's `<title>`, its heading and the Code Challenge line). The
rename writes it with `JSON.stringify`, so any name the card's pattern admits —
apostrophes and ampersands included — stays a valid string; Astro escapes it
where it renders. The heading keeps its "Welcome to", which is what the
deploy's smoke matches: the name is the owner's.

**The deploy config is committed.** The adapter writes a deployable
`dist/server/wrangler.json` beside the Worker it emits, and AB1's component
named it. But the composition's lane checks that `wranglerConfig` exists
*before* `build-app` (`verify-app-structure`), and orun stages each job's tree
without `dist/` — every lane would have stopped there. `wrangler.deploy.jsonc`
is that file written down: the built entry (`./dist/server/entry.mjs`,
`no_bundle`, the chunks as ES modules) and the client output as assets, with
`wrangler.jsonc`'s settings. Two guards keep it honest: the app's own tests
fail when it and `wrangler.jsonc` disagree (an owner adding a binding to
one), and the baseline's end-to-end tier dry-runs it against the adapter's
generated config over the same build and fails if they would upload
different Workers (an adapter upgrade changing its output).

**The site's CI is on from its first commit.** `ci.yml` used to wait for an
`ORUN_CI` repository variable, which a bootstrap has no way to set: every site
would have converged on nothing. It now plans nothing only while
`intent.yaml` names the placeholder `ws_CHANGE_ME`, which this repository
carries and no site does (the scaffold writes the site's workspace, or
`ws_SET_ME`, which fails loudly).

**Testing without the platform.** `testing/lib/bootstrap.sh` places every
phase and runs the blueprint's own `run:` hooks, read out of the document, so
the whole bootstrap short of the platform's typed actions runs in CI on every
pull request; `testing/e2e.test.sh` then replays the stage lane's steps in a
job tree staged as orun stages it, serves what it built and runs the
component's own smoke against it.
