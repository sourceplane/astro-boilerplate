# astro-boilerplate (AB) — Implementation status

As-built ≠ intent. This file records what actually shipped, and every place
the code departed from `design.md` or from the upstream template.

| Milestone | State | PR |
|---|---|---|
| AB0 — the spec | ✅ Shipped | [#1](https://github.com/sourceplane/astro-boilerplate/pull/1) |
| AB1 — the site on Workers | ✅ Shipped | [#2](https://github.com/sourceplane/astro-boilerplate/pull/2) |
| AB2 — ready to instantiate | ✅ Shipped | [#3](https://github.com/sourceplane/astro-boilerplate/pull/3) |

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

## Verified

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
