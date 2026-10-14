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
the port drops the unused dependency), a custom domain, and Cache Rules for
the SWR page (an account-level setting).
