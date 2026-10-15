# apps/web — the site

An [Astro](https://astro.build/) site from Vercel's
[Astro boilerplate](https://github.com/vercel/examples/tree/main/framework-boilerplates/astro)
(MIT), running on Cloudflare Workers + Static Assets through Astro's own
[`@astrojs/cloudflare`](https://docs.astro.build/en/guides/integrations-guide/cloudflare/)
adapter:

- `/` — a static page, pre-rendered at build time and served from the assets
- `/ssr` — a page rendered by the Worker on every request
- `/ssr-with-swr-caching` — the same, with a `Cache-Control: s-maxage=10,
  stale-while-revalidate` header (Cloudflare caches it once a Cache Rule
  covers the route)
- `/image` — an [Astro asset](https://docs.astro.build/en/guides/images/)
  through `astro:assets`
- Cloudflare Web Analytics (set `PUBLIC_CF_BEACON_TOKEN` at build time)

The site's name — the home page's heading and title — is in `src/site.ts`.
Pages are `.astro` files in `src/pages/`; each is a route named for its file.
Components and layouts live in `src/components/` and `src/layouts/`, static
files in `public/`.

```bash
pnpm dev        # astro dev on http://localhost:4321
pnpm test       # vitest over Astro's container API (src/test)
pnpm build      # astro build → dist/server (the Worker) + dist/client (assets)
pnpm preview    # wrangler dev over the built Worker
```

`wrangler.jsonc` is what the adapter builds from — the Worker's name, its
compatibility and its bindings. `wrangler.deploy.jsonc` is what deploys and
what `pnpm preview` serves: the same settings, pointed at the built Worker.
Add a binding to both; `src/test/deploy-config.test.ts` fails when they
disagree.

How it is deployed — per environment, on merge to `main` — is the
repository's README and `component.yaml` beside this file.
