# astro-boilerplate (AB) — Implementation status

As-built ≠ intent. This file records what actually shipped, and every place
the code departed from `design.md` or from the upstream template.

| Milestone | State | PR |
|---|---|---|
| AB0 — the spec | | |
| AB1 — the site on Workers | | |
| AB2 — ready to instantiate | | |

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
