# astro-boilerplate

An [Astro](https://astro.build/) site — a pre-rendered home page, two
server-rendered pages (one with stale-while-revalidate cache headers) and an
image page — on **Cloudflare Workers + Static Assets** through Astro's own
[`@astrojs/cloudflare`](https://docs.astro.build/en/guides/integrations-guide/cloudflare/)
adapter.

## Live deployment

<!-- 03-docs:begin -->
Not recorded yet. The bootstrap's last phase writes the live URLs, the
workspace and the secrets the site uses into
[ai/context/deployment.md](ai/context/deployment.md); how the site deploys
and how to operate it is in
[ai/context/operations.md](ai/context/operations.md).
<!-- 03-docs:end -->

## What is here

| Surface | Where |
|---|---|
| The site's name (the home page's heading and title) | `apps/web/src/site.ts` |
| `/` (pre-rendered), `/ssr`, `/ssr-with-swr-caching`, `/image` | `apps/web/src/pages` |
| Layout (with the optional analytics beacon) and the link card | `apps/web/src/layouts/Layout.astro`, `apps/web/src/components/Card.astro` |
| Workers build and deploy contract | `apps/web/astro.config.ts`, `wrangler.jsonc` (what the adapter builds from), `wrangler.deploy.jsonc` (what deploys), `component.yaml` |
| Tests (Astro's container API) | `apps/web/src/test` |

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

Make the site yours in `apps/web/src/pages/` (a page per route) and
`apps/web/src/site.ts` (its name). A binding the Worker needs (KV, R2, D1, a
variable) goes in both `apps/web/wrangler.jsonc` and
`apps/web/wrangler.deploy.jsonc`; the app's tests fail when they disagree.

One optional build-time variable (`apps/web/.env.example`):

| Variable | What it does |
|---|---|
| `PUBLIC_CF_BEACON_TOKEN` | Cloudflare Web Analytics token (dashboard → Web Analytics → add a site). Unset, no script is rendered. |

`/ssr-with-swr-caching` sends `Cache-Control: s-maxage=10,
stale-while-revalidate`. Cloudflare caches a Worker's response only when a
Cache Rule covers the route: add one for that path to have it cached at the
edge; without one it renders on every request.

## How it deploys

Merges to `main` converge through [Orun](https://opencode.ai/docs):
`.github/workflows/ci.yml` plans the changed components and runs each lane
against the workspace in `intent.yaml`. The site deploys to `stage`, then to
`prod` once stage has converged on the same commit; `dev` only verifies. The
Worker is `astro-boilerplate-web-<env>` on your account's workers.dev
subdomain, and every deploy is smoke-tested over HTTP. A pull request runs
the same pipeline's verify lanes: the site built and dry-deployed for each
environment, with nothing deployed. They do not type-check, lint or run the
tests, so run `pnpm typecheck`, `pnpm lint` and `pnpm test` before you push.
(A push to `main` builds, deploys and smoke-tests.)

The pipeline holds one credential, GitHub's own `GITHUB_TOKEN`. The
Cloudflare token and account id are brokered per run from the workspace's
Cloudflare connection; nothing provider-shaped is stored in the repository
or in GitHub.

## Custom domain

The site answers on workers.dev from its first deploy. To serve it on your
own domain:

1. Add the domain to the Cloudflare account the site deploys into, and attach
   it to the Worker (dashboard → Workers & Pages →
   `astro-boilerplate-web-prod` → Settings → Domains & Routes → Add →
   Custom domain). Do the same for stage with a subdomain if you want one.
2. Record the environment's public origin in `intent.yaml`, so the
   deployment record probes it beside the workers.dev URL:

   ```yaml
   environments:
     prod:
       env:
         SITE_URL: https://astro-boilerplate.example.com
   ```

   The site was born with the reserved placeholder
   `astro-boilerplate.example.com` where its domain goes: that example, and
   `BASE_DOMAIN` under each environment (dev, stage and prod) in
   `intent.yaml`. Replace it with your domain in the same change.

The site builds no absolute links, so nothing needs rebuilding for the domain
to serve it.
