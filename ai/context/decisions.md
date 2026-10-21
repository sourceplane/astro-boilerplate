# astro-boilerplate — decisions

The choices that shape this repository, one line each, with where the full
reasoning lives. Superseded decisions stay listed, marked, so the history
reads in order.

| # | Decision | Why | Source |
|---|---|---|---|
| 1 | Astro's own Cloudflare adapter (`@astrojs/cloudflare`) on Workers + Static Assets, not OpenNext | Astro is not Next: swapping `@astrojs/vercel` for the native adapter is the whole port | `specs/epics/astro-boilerplate/README.md` (decisions locked), design.md |
| 2 | Astro 7 + adapter 14, `session: false`, `imageService: 'compile'` | The current adapter needs Astro ≥ 7.2; the template keeps no session state (no KV namespace to bind); the Worker has no sharp | risks AB-A, AB-E, AB-C |
| 3 | The tests live in the app (`apps/web/src/test`), not a `tests/web` package | Astro components render only under Astro's own Vite config | risks AB-D, AB-F |
| 4 | The deploy hands wrangler a committed `wrangler.deploy.jsonc`, held to the adapter's generated config by the app's tests and the e2e tier | The lane checks for the config before the build, in a job tree staged without `dist/` | risk AB-I, design.md |
| 5 | The site's name is one seam, `SITE_NAME` in `apps/web/src/site.ts` | The rename rewrites one literal; the framework's own name elsewhere is content | IMPLEMENTATION-STATUS (departures) |
| 6 | No custom-domain phase: a domain is the owner's step, and `SITE_URL` has the record probe it | The brokered `workers-deploy` token has no zone scope | risk AB-H |
| 7 | ~~Three phases: `01-scaffold`, `02-site`, `03-docs`~~ (`baseline-v1`) — superseded by #8 | — | IMPLEMENTATION-STATUS, "One landing (AB4)" |
| 8 | One landing (`01-product`) then the record (`03-docs`); each bootstrap pull request checked by `plan` alone | A landing has a fixed cost; the convergence on main builds, deploys and smoke-tests the site for real (cirrus-baseline baseline-v22) | IMPLEMENTATION-STATUS (AB4) |
| 9 | `ci.yml` plans nothing while `intent.yaml` names `ws_CHANGE_ME`; `checks.yml` runs on pull requests only | A bootstrap cannot set a repository variable; a push to main must start `ci.yml` alone | IMPLEMENTATION-STATUS (AB3), risk AB-K |
| 10 | stack-tectonic 0.19.0, not 0.20.0 | The job installs in its own tree; 0.20.0's lane-shared install broke the Next.js sibling live and would save nothing here | risk AB-J |
| 11 | orun is pinned only where it runs (the `orun-action` `version:` in each workflow); no kiox | `kiox.yaml` pinned a version (v2.15.0) nothing ran | IMPLEMENTATION-STATUS (AB5) |
| 12 | Component docs are generated from the manifests and checked in CI | A hand-written copy of the component's facts drifts silently | `tooling/catalog/gen-component-docs.py` |
| 13 | `subdomain` is read from the Cloudflare connection (`from: connection.cloudflare.workersSubdomain`), never asked | It belongs to the account like its id and has one right answer; a typed one could only be wrong, and showed up after deploy in the smoke and the probes | `blueprint.yaml`, IMPLEMENTATION-STATUS (AB-7) |
