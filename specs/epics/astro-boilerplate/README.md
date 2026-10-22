# Epic: astro-boilerplate (AB)

**Vercel's Astro boilerplate is four pages that exercise what a framework adapter must do — pre-render, server-render, set cache headers, optimise an image — and on Cloudflare the adapter is Astro's own. Swapping `@astrojs/vercel` for `@astrojs/cloudflare` is the whole port; the pages do not change. What the repository adds is the Cirrus baseline shape around it: an Orun intent, a component that deploys the adapter's Worker and assets, a credential-free checks lane, and an Orun lane that turns on when the product is linked.**

This is the first port without OpenNext. It establishes the shape for every framework with a native Cloudflare adapter (SvelteKit, Nuxt, Remix/React Router, Hono): the `cloudflare-workers-assets-turbo` component takes any Worker entrypoint plus any assets directory.

## Status

| Field | Value |
|-------|-------|
| Status | ✅ AB0–AB6 shipped (#1–#7): AB0–AB3 (#1–#4) tagged `baseline-v1`, which went live from the console on 2026-10-15 (7m07s); AB4 — one landing (#5, AB-5) — and AB5 — the cirrus standard (#6, AB-6 and AB-7) — tagged `baseline-v2`; AB6 — the domain is set later (#7, AB-8) — tagged `baseline-v3`. The one-landing shape is not yet proven live (risk AB-G) |
| Cluster | **AB** (AB0–AB6) |
| Owner(s) | `apps/web` (the site, with its container-API tests) |
| Builds on | `cirrus-baseline` conventions; the `blog-starter` port's repository shape |
| Upstream | [vercel/examples `framework-boilerplates/astro`](https://github.com/vercel/examples/tree/main/framework-boilerplates/astro) |
| Changes | Adapter swap, Cloudflare Web Analytics beacon in the layout, build-time image service; the pages, layout and component are untouched but for the home page reading the site's name from `src/site.ts` (AB3) |
| Decisions locked | (1) Astro's Cloudflare adapter, not OpenNext (Astro is not Next). (2) `imageService: 'compile'` — the Worker has no sharp. (3) Tests live in the app (Astro's container API needs Astro's Vite config). (4) Astro 7 + adapter 14 (current majors; the template floats `^5`). (5) The deploy hands wrangler a committed `wrangler.deploy.jsonc`, held to the adapter's generated config (AB3). |
| Gate | AB1 is the first user-visible rung. |
| Shipped as | `baseline-v1` ([#4](https://github.com/sourceplane/astro-boilerplate/pull/4), three phases; live 2026-10-15, 7m07s), then `baseline-v2` (AB4: [#5](https://github.com/sourceplane/astro-boilerplate/pull/5); AB5: [#6](https://github.com/sourceplane/astro-boilerplate/pull/6)), then `baseline-v3` (AB6: [#7](https://github.com/sourceplane/astro-boilerplate/pull/7), no domain asked); the one-landing shape proven offline (Baseline CI), not yet live |

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
| AB3 — a baseline | card, build document, rename, bootstrap tooling, tests; a deploy config the lanes can find before they build | a new site goes from nothing to live in three phases; Baseline CI green |
| AB4 — one landing | the site in one landing, each bootstrap landing checked by `plan` alone (cirrus-baseline baseline-v22's shape) | a site bootstrapped from the next tag is live faster than baseline-v1's 7m07s |
| AB5 — the cirrus standard | no kiox, generated component docs, the context pack, status that agrees with the tags and the live record; the subdomain read from the Cloudflare connection | Baseline CI green with the docs check; the card asks for no subdomain |
| AB6 — the domain is set later | the console asks for no domain; an empty `productdomain` brands the placeholder `<reponame>.example.com` for an owner to replace | Baseline CI green on a fixture with no domain |
