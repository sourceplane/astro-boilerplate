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

## AB-G — The one-landing shape is not yet proven live (OPEN)

`baseline-v1` was: a console bootstrap of it (AB3's three phases,
`01-scaffold`, `02-site`, `03-docs`) went live on stage and prod on
2026-10-15 — `astro-live`, `bst_XYM9M4ZT`, 7m07s end to end
(IMPLEMENTATION-STATUS, "One landing (AB4)"). What `main` builds now is
AB4's shape — the whole site in one landing (`01-product`), then the record
(`03-docs`), each bootstrap pull request checked by `plan` alone — and that
is proven offline on every pull request: the card against the build, the
blueprint read by the pinned orun, the leak gate, the offline bootstrap with
the blueprint's own hooks, the site's own plan for the 01-product merge, and
the produced site built, dry-deployed, served and smoke-tested in a job tree
staged as orun stages it. It has not been bootstrapped live; `baseline-v2`
is the first tag that carries it. Closes with one bootstrap from
`baseline-v2`, whose timing replaces the 5-minute estimate.

(Updated in AB5. Until then this entry read "No live bootstrap yet" and
cited the 02-site merge, a phase AB4 removed.)

## AB-H — A custom domain is the owner's step (ACCEPTED)

Attaching a domain to a Worker needs zone-level permissions. The platform
brokers `workers-deploy` (Workers Scripts, KV, account read — no DNS) and
`dns-edit` only with zone ids, which a build does not have. Rather than ship a
parked component (Cirrus's `07-domain` is one), the site's README says how to
attach the domain, and `SITE_URL` in `intent.yaml` has the deployment record
probe it. The site builds no absolute links, so the build does not read it.

## AB-I — The lanes looked for the deploy config before the build made it (RESOLVED)

AB1's component named the adapter's generated config,
`wranglerConfig: dist/server/wrangler.json`. The composition's
`verify-app-structure` step runs `test -f <wranglerConfig>` right after the
install and BEFORE `build-app`, in the component's directory of a job tree
orun stages without `dist/` (`outputDirs`, orun `internal/runner/workspace.go`)
and that a CI checkout never has anyway. Every lane — the pull-request
verify lanes and the deploy lanes alike — would have stopped there. Nothing
had run a lane: the repository was never linked, and the checks lane only
builds.

Fix: the component names a committed `apps/web/wrangler.deploy.jsonc` —
the generated config's deploy-relevant settings written down (the built
entry, `no_bundle`, the chunks as ES modules, `dist/client` as assets) with
`wrangler.jsonc`'s name, compatibility and bindings. `wrangler.jsonc` stays
what the adapter builds from: it cannot carry the `main` a deploy needs,
because the adapter takes the user's `main` as the entry to BUILD.

Rejected: building in the install step (`installCommand: … && turbo run
build`), which passes the check but reports a broken build as a broken
install; and a shell expression in `wranglerConfig`.

Guards: `src/test/deploy-config.test.ts` fails when `wrangler.deploy.jsonc`
and `wrangler.jsonc` disagree on anything but the deploy-only keys, so an
owner who adds a binding to one is told; `testing/e2e.test.sh` replays
`verify-app-structure` in a staged tree (red on AB2's config, green on the
fix) and dry-runs both configs over the same build, failing if they would
upload different Workers — which is how an adapter upgrade that changes its
output would surface.

## AB-J — stack-tectonic 0.19.0, not 0.20.0 (SETTLED)

0.20.0 marks the workspace install `scope: lane`; orun ≥ 2.78.2 then installs
once in the source checkout and stages each job's tree with its top-level
`node_modules` as a symlink out of the tree. The Next.js sibling
(`portfolio-starter-kit`, its PK-J) died on it live: Turbopack refuses a
dependency that resolves outside its root. Astro builds with Vite, and a
build and a dry deploy of this site in that layout succeeded when tried by
hand — but no deploy has run from it, and with one job per lane
(`lane: isolated`) the shared install would save nothing. The site pins
0.19.0, where the job installs in its own tree, and `testing/e2e.test.sh`
stages the job with whichever layout the pinned composition plans, so a bump
is tested, not assumed.

## AB-K — One workflow on a push to main (RESOLVED, inherited)

`orun.run/watch@v1` with `sha:` takes the newest workflow run for the commit
from ANY workflow. The sibling's first live bootstrap watched `checks.yml` go
green while `ci.yml`'s deploy lanes had failed (its PK-K). `checks.yml` here
runs on pull requests and `workflow_dispatch` only, and
`testing/coverage.test.sh` fails if a shipped workflow other than `ci.yml`
runs on a push to main.
