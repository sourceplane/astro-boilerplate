# astro-boilerplate — risks and open questions

## AB-A — Astro 5 → 7 (RESOLVED)

The template floats `astro ^5.1`; the current Cloudflare adapter (14) needs
Astro ≥ 7.2. The port uses the current majors. Nothing the four pages use
changed between the majors (`output: 'server'`, `prerender`, `astro:assets`
`<Image>`, `Astro.response.headers`); the build and the preview verify it.
Pinning Astro 5 with adapter 12 is the fallback.

## AB-B — Cache headers on a Worker (ACCEPTED, documented)

Vercel's CDN honours `s-maxage` on serverless responses by default;
Cloudflare caches dynamic Worker responses only through a Cache Rule or the
Cache API. The header is emitted as upstream wrote it and the README says
what to configure. Changing the page to use the Cache API would be a code
change the template did not ask for.

## AB-C — Image optimisation in the Worker (RESOLVED, with a caveat)

`imageService: 'compile'` optimises at build time; the Worker never runs
sharp. The template's `image.astro` is not pre-rendered, so its image goes
through the adapter's passthrough endpoint (`/_image?…`) and arrives as the
original PNG, not a resized WebP as on Vercel. Adding `export const
prerender = true` to that page would optimise it at build; the page is kept
as upstream wrote it. The adapter's `cloudflare` image service (Cloudflare
Images binding) is the alternative for request-time optimisation.

## AB-E — The adapter's default KV sessions (RESOLVED)

Astro 7's Cloudflare adapter turns on KV-backed sessions unless told not
to, and the generated config then binds a `SESSION` KV namespace that a
deploy would need. The template keeps no session state: `session: false`
in `astro.config.ts`.

## AB-F — Vitest and the Cloudflare Vite plugin (RESOLVED)

`getViteConfig` with the adapter pulls in the Cloudflare Vite plugin, whose
`cloudflare:workers` import breaks vitest's dependency optimisation. The
test config passes `configFile: false` so components render under Astro's
plain Vite config.

## AB-D — Tests inside the app (SETTLED)

Astro components render only under Astro's Vite plugin, so vitest runs in
`apps/web` with `getViteConfig`. The repository convention of a separate
`tests/<app>` package is kept for the Next.js ports; here it would only add
a second Astro toolchain.
