# astro-boilerplate

Vercel's [Astro boilerplate](https://github.com/vercel/examples/tree/main/framework-boilerplates/astro)
— a pre-rendered home page, two server-rendered pages (one with
stale-while-revalidate cache headers) and an optimised-image page — running
on **Cloudflare Workers + Static Assets** through Astro's own
[`@astrojs/cloudflare`](https://docs.astro.build/en/guides/integrations-guide/cloudflare/)
adapter, and packaged as an **Orun baseline**: one command takes a new site
from nothing to live on stage and prod, in its own repository, under its own
name.

Swapping the Vercel adapter for the Cloudflare one is the whole port; the
pages do not change, except that the home page reads the site's name from one
module. What the baseline adds is everything needed to make a copy of it
somebody else's — built the way
[cirrus-baseline](https://github.com/sourceplane/cirrus-baseline) is. See
[`specs/epics/astro-boilerplate`](specs/epics/astro-boilerplate/README.md)
for the design, the milestones and the as-built status.

## Instantiating a site

```bash
git clone --depth 1 --branch <baseline-tag> https://github.com/sourceplane/astro-boilerplate
cd astro-boilerplate
orun new --blueprint repo-blueprint.yaml --out ~/sites/acme-notes --run-hooks --resume \
  --set reponame=acme-notes --set productname="Acme Notes" \
  --set githuborg=acme-inc --set subdomain=<workers-dev-subdomain>
```

Or, once the platform's registry lists it, from the Orun console (Baselines →
`astro-boilerplate` → Build). Two phases — `01-product` (the repository
created, then the whole site in one pull request, deployed to stage and prod
and smoke-tested) and `03-docs` (the live deployment recorded) — each landing
one pull request in the new repository. **[BOOTSTRAP.md](BOOTSTRAP.md)** is the
operator guide; [docs/phases/](docs/phases/README.md) has a page per phase.

The new repository receives the **site only** — the app and its tests, its
CI, its tooling, a README of its own and its operating contract — renamed
throughout to the site's name, repository and Cloudflare Worker. None of this
repository's machinery ships.

| What makes it a baseline | Where |
|---|---|
| The console card (inputs, secrets, programme) | `blueprint.yaml` |
| The build document (modules, phases, hooks) | `repo-blueprint.yaml` |
| This tree's identity, and the bootstrap's task contracts | `.baseline/` |
| The rename engine | `tooling/rebrand/rebrand.mjs` |
| The bootstrap's helpers (deferrals, redeploy marker, work-tree strip) | `tooling/bootstrap/` |
| The deployment-record renderer | `hooks/render-deployment-docs.sh` |
| The site's README and context pack | `.baseline/product/README.md`, `ai/context/` |
| The baseline's tests: contract, leak, offline bootstrap, end to end | `testing/`, `.github/workflows/baseline.yml` |
| Cutting a `baseline-vN` tag | `.github/workflows/tag.yml` |

## What is here (the site)

| Surface | Where |
|---|---|
| The site's name (the home page's heading and title) | `apps/web/src/site.ts` |
| `/` (pre-rendered), `/ssr`, `/ssr-with-swr-caching`, `/image` | `apps/web/src/pages` |
| Layout (with the optional analytics beacon) and the link card | `apps/web/src/layouts/Layout.astro`, `apps/web/src/components/Card.astro` |
| Adapter, Worker config, deploy contract | `apps/web/astro.config.ts`, `apps/web/wrangler.jsonc` (what the adapter builds from), `apps/web/wrangler.deploy.jsonc` (what deploys), `apps/web/component.yaml` |
| Tests (Astro container API) | `apps/web/src/test` |

## Getting started

```bash
pnpm install
pnpm typecheck        # astro check
pnpm test             # vitest over the container API
pnpm build            # astro build → apps/web/dist/server (Worker) + dist/client (assets)
```

```bash
pnpm --filter @app/web dev        # http://localhost:4321
pnpm --filter @app/web preview    # wrangler dev over the built Worker
```

Optional: `PUBLIC_CF_BEACON_TOKEN` at build time renders the Cloudflare Web
Analytics beacon (stands in for the Vercel adapter's web analytics).

## How it maps to Vercel

| Vercel | Here |
|---|---|
| `@astrojs/vercel` serverless output | `@astrojs/cloudflare`: Worker under `dist/server/`, static output under `dist/client/` |
| Vercel image optimisation | Build-time optimisation (`imageService: 'compile'`) for pre-rendered pages; the SSR `/image` page serves the original through the adapter's passthrough endpoint |
| Web analytics | Cloudflare Web Analytics beacon, opt-in by token |
| `s-maxage` / `stale-while-revalidate` honoured by the CDN | Header emitted unchanged; add a Cache Rule for `/ssr-with-swr-caching` to have Cloudflare cache it |
| Deploy on push | Orun deploys `<repo>-web-{stage,prod}` on merge to `main` (`apps/web/component.yaml`) |
| "Deploy with Vercel" (clone the template) | `orun new --blueprint repo-blueprint.yaml` — a new repository, branded, deployed |

## CI

| Workflow | What it runs | Ships to a site |
|---|---|---|
| `ci.yml` | the Orun pipeline, and the only workflow a site carries: `orun plan --changed`, then one job per lane. A pull request runs the verify lanes (the site built and dry-deployed per environment — they do not type-check, lint or run the tests; `baseline.yml`'s e2e tier runs those before each tag, and a site's README asks its developers to run them before a push), except the bootstrap's own landings (`orun/BASE-*`), which are checked in the box before they are pushed (`checks: local`) and whose PR runs `plan` alone; a merge deploys stage → prod. It plans nothing while `intent.yaml` names the placeholder workspace `ws_CHANGE_ME`, as this repository does | yes |
| `baseline.yml` | the baseline's own tiers: contract tests, the blueprint read by the pinned orun, the leak gate, the offline bootstrap, the site built, dry-deployed and served | no |
| `tag.yml` | cuts a `baseline-vN` tag (manual) | no |
