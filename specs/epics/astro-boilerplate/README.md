# Epic: astro-boilerplate (AB)

**Vercel's Astro boilerplate is four pages that exercise what a framework adapter must do — pre-render, server-render, set cache headers, optimise an image — and on Cloudflare the adapter is Astro's own. Swapping `@astrojs/vercel` for `@astrojs/cloudflare` is the whole port; the pages do not change. What the repository adds is the Cirrus baseline shape around it: an Orun intent, a component that deploys the adapter's Worker and assets, a credential-free checks lane, and an Orun lane that turns on when the product is linked.**

This is the first port without OpenNext. It establishes the shape for every framework with a native Cloudflare adapter (SvelteKit, Nuxt, Remix/React Router, Hono): the `cloudflare-workers-assets-turbo` component takes any Worker entrypoint plus any assets directory.

## Status

| Field | Value |
|-------|-------|
| Status | Draft |
| Cluster | **AB** (AB0–AB2) |
| Owner(s) | `apps/web` (the site, with its container-API tests) |
| Builds on | `cirrus-baseline` conventions; the `blog-starter` port's repository shape |
| Upstream | [vercel/examples `framework-boilerplates/astro`](https://github.com/vercel/examples/tree/main/framework-boilerplates/astro) |
| Changes | Adapter swap, Cloudflare Web Analytics beacon in the layout, build-time image service; the pages, layout and component are untouched |
| Decisions locked | (1) Astro's Cloudflare adapter, not OpenNext (Astro is not Next). (2) `imageService: 'compile'` — the Worker has no sharp. (3) Tests live in the app (Astro's container API needs Astro's Vite config). (4) Astro 7 + adapter 14 (current majors; the template floats `^5`). |
| Gate | AB1 is the first user-visible rung. |
| Shipped as | |

## Read order

1. `design.md` — what maps to what, the build, what is out of scope
2. `implementation-plan.md` — the milestones and what "done" means for each
3. `risks-and-open-questions.md` — what could go wrong and what was decided
4. `IMPLEMENTATION-STATUS.md` — what actually shipped (kept distinct from intent)

## Milestones at a glance

| Milestone | What it lands | Done when |
|---|---|---|
| AB0 — the spec | this doc set and the task contracts | merged on `main` |
| AB1 — the site on Workers | `apps/web` with the Cloudflare adapter, tests, green checks | `wrangler dev` serves all four pages; Checks green |
| AB2 — ready to instantiate | README, as-built status | a reader can run, test, preview and deploy it |
