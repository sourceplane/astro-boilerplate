# astro-boilerplate

Vercel's [Astro boilerplate](https://github.com/vercel/examples/tree/main/framework-boilerplates/astro)
— a pre-rendered home page, two server-rendered pages (one with
stale-while-revalidate cache headers) and an optimised-image page — running
on **Cloudflare Workers + Static Assets** through Astro's own
[`@astrojs/cloudflare`](https://docs.astro.build/en/guides/integrations-guide/cloudflare/)
adapter, inside the repository conventions of the
[Cirrus baseline](https://github.com/sourceplane/cirrus-baseline).

Swapping the Vercel adapter for the Cloudflare one is the whole port; the
pages do not change. See
[`specs/epics/astro-boilerplate`](specs/epics/astro-boilerplate/README.md)
for the design, the milestones and the as-built status.

## What is here

| Surface | Where |
|---|---|
| `/` (pre-rendered), `/ssr`, `/ssr-with-swr-caching`, `/image` | `apps/web/src/pages` |
| Layout (with the optional analytics beacon) and the link card | `apps/web/src/layouts/Layout.astro`, `apps/web/src/components/Card.astro` |
| Adapter, Worker config, deploy contract | `apps/web/astro.config.ts`, `apps/web/wrangler.jsonc` (the adapter derives `dist/server/wrangler.json` from it), `apps/web/component.yaml` |
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
| Deploy on push | Orun deploys `astro-boilerplate-web-{stage,prod}` on merge to `main` |

## Deploying

`.github/workflows/checks.yml` runs install, typecheck, lint, test and build
on every push and pull request. `ci.yml` is the Orun pipeline: set
`execution.state.workspace` in `intent.yaml` to this product's workspace
(`orun cloud link`), connect a Cloudflare account to it, and set the
`ORUN_CI` repository variable to `true`. A merge to `main` then deploys the
Worker to `stage`, then `prod`.
